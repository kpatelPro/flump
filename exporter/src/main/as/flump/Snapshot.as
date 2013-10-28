//
// Flump - Copyright 2013 Ken Patel

package flump {

import fl.motion.AdjustColor;
import flash.display.BitmapData;
import flash.display.DisplayObject;
import flash.display.DisplayObjectContainer;
import flash.display.MovieClip;
import flash.display.Sprite;
import flash.display.StageQuality;
import flash.filters.BevelFilter;
import flash.filters.BitmapFilter;
import flash.filters.BlurFilter;
import flash.filters.ColorMatrixFilter;
import flash.filters.DropShadowFilter;
import flash.filters.GlowFilter;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.utils.Dictionary;

import flump.executor.load.LoadedSwf;
import flump.xfl.XflLibrary;
import flump.xfl.XflMovie;

import flump.mold.MovieMold;

import com.threerings.display.DisplayUtil;

/* 
 * Snapshot
 * 
 * Exports png images that are snapshots of a flash symbol.
 * 
 * To specify snapshots, add an entry to the .flump project file as so:
  "exports": [
    {
      "snapshots": {
        "<snapshot_name>": {
          "maxWidth": 187,
          "maxHeight": 153,
          "movieName": "<symbol_name>",
          "filters": [
            {
              "name": "GlowFilter",
              "color": "#ffff00"
            }
          ],
          "clipBoundsOptional": true,
          "clipBoundsSymbol": [
            "bounds_store_icon"
          ]
        }
      },
      ...
    }
 * 
 */
    
public class Snapshot
{
    public static function fromDescriptor (lib :XflLibrary, descriptor :Object) :Snapshot {
        // get MovieMold
        var movieName :String = descriptor.movieName;
        if (!movieName) return null;
        if (!lib.hasItem(movieName)) return null;
        const mold :MovieMold = lib.getItem(movieName);
        if (!mold) return null;
        
        // get symbol movieclip
        const klass :Class = Class(lib.swf.getSymbol(movieName));
        if (!klass) return null;
        const mc :MovieClip = MovieClip(new klass());
        if (!mc) return null;

        // get clip info
        var clipRect :Rectangle = null; 
        var clipRectXform :Array = null; // identity transform
        // if clipping with a bounds name, set the clip values
        if (descriptor.clipBoundsSymbol) {
            // if is array, check for any of the names in the array
            var clipBoundsSymbols :Array = (descriptor.clipBoundsSymbol as Array) ? descriptor.clipBoundsSymbol : [descriptor.clipBoundsSymbol];
            for each (var clipBoundsSymbol :String in clipBoundsSymbols) {
                // get bounds
                clipRect = lib.getBoundsSymbolBounds(clipBoundsSymbol);
                // get translation matrix
                clipRectXform = lib.getBoundsSymbolXformForMovie(clipBoundsSymbol, mold);
                if (clipRect && clipRectXform) break;
            }
            if (!clipRect || !clipRectXform) {
                // if clipBounds is not optional, return null
                if (!descriptor.clipBoundsOptional) {
                    return null;
                }
                // fall through and use full image
                clipRect = null;
                clipRectXform = null;
            }
        }
        // otherwise no clipping

        // create snapshot
        return new Snapshot(descriptor, mc, clipRect, clipRectXform);
    }
    
    public function Snapshot (descriptor :Object, disp :DisplayObjectContainer, clipRect :Rectangle, clipRectXform :Array) {
        _descriptor = descriptor;
        _disp = disp;
        _clipRect = clipRect; // ? clipRect : _disp.getBounds(_disp);
        _clipRectXform = clipRectXform; // ? clipRectXform : [1, 1, 0, 0]; // identity
    }
    
    public function toBitmapData () :BitmapData {
        
        // render clip to bitmap data
        var bmd :BitmapData;
        if (_clipRect) {
            bmd = toBitmapDataWithClip();
        } else {
            bmd = toBitmapDataNoClip();
        }

        // apply filters if requested
        var filtersParam :Array = _descriptor.filters ? _descriptor.filters : [];
        for each (var filterDesc:Object in filtersParam) {
            var filter :BitmapFilter = filterFromDesc(filterDesc);
            if (filter) {
                bmd.applyFilter(bmd, bmd.rect, bmd.rect.topLeft, filter);
            }
        }
        
        // add border if requested
        var borderParam :Number = Number(_descriptor.border);
        if (!isNaN(borderParam)) {
            var border :int = int(borderParam);
            var paddedBmd :BitmapData = new BitmapData(bmd.width + 2 * border, bmd.height + 2 * border, true, 0x00);
            paddedBmd.copyPixels(bmd, bmd.rect, new Point(border, border));
            bmd.dispose();
            bmd = paddedBmd;
        }
        
        return bmd;
    }
    
    public function toBitmapDataWithClip () :BitmapData {
        
        // parse xform parameters
        var clipScaleX :Number = _clipRectXform[0];
        var clipScaleY :Number = _clipRectXform[1];
        var clipOffsetX :Number = _clipRectXform[2];
        var clipOffsetY :Number = _clipRectXform[3];
        
        // calculate transformed clip bounds
        var clipRect :Rectangle = new Rectangle(
            _clipRect.x * clipScaleX, 
            _clipRect.y * clipScaleY, 
            _clipRect.width * clipScaleX, 
            _clipRect.height * clipScaleY); 
        clipRect.offset(clipOffsetX, clipOffsetY);

        // offset upper left
        var m :Matrix = new Matrix();
        m.translate( -(_disp.x + clipRect.x), -(_disp.y + clipRect.y));
        clipRect.offset( -clipRect.x, -clipRect.y);

        // adjust scale
        var scale :Number = getDesiredScale(clipRect.width, clipRect.height);
        m.scale(scale, scale);
        clipRect.width *= scale;
        clipRect.height *= scale;

        // render with vector renderer
        var bmd :BitmapData = new BitmapData(Math.ceil(clipRect.width), Math.ceil(clipRect.height), true, 0x00);
        bmd.drawWithQuality(_disp, m, null, null, clipRect, true, StageQuality.BEST);

        // return result
        return bmd;
    }

    public function toBitmapDataNoClip () :BitmapData {
        
        // swfTexture has functionality to check for visible bounds (from filters), so let's leverage that
        var swfTexture :SwfTexture = new SwfTexture('snapshot', _disp, 1.0, StageQuality.BEST);
        
        // adjust scale
        var scale :Number = getDesiredScale(swfTexture.w, swfTexture.h);
        swfTexture.setScale(scale);

        // create bitmap data
        return swfTexture.toBitmapData();
    }

    // get desired uniform scale
    public function getDesiredScale (dispWidth :Number, dispHeight :Number) :Number {
        
        var scale:Number = 1.0;
        var desiredWidth :Number = NaN;
        var desiredHeight :Number = NaN;
        
        // get params from descriptor
        if (_descriptor.maxWidth) desiredWidth = _descriptor.maxWidth;
        if (_descriptor.maxHeight) desiredHeight = _descriptor.maxHeight;
        if (_descriptor.border) {
            // render object smaller than final png size to leave room for a whitespace border 
            var borderParam :Number = Number(_descriptor.border);
            var border :int = !isNaN(borderParam) ? int(borderParam) : 0;
            desiredWidth -= 2 * border;
            desiredHeight -= 2 * border;
        }
        
        // grow/shrink size to fit snugly within desired width/height, preserving aspect ratio        
        if (!isNaN(desiredWidth) && !isNaN(desiredHeight)) {
            var scaleX:Number = desiredWidth / dispWidth;
            var scaleY:Number = desiredHeight / dispHeight;
            scale = Math.min(scaleX, scaleY);
        } else if (!isNaN(desiredWidth)) {
            scale = desiredWidth / dispWidth;
        } else if (!isNaN(desiredHeight)) {
            scale = desiredHeight / dispHeight;
        }

        // return scale
        return scale;
    }

    private function filterFromDesc (object :Object) :BitmapFilter {
        var filter :BitmapFilter = null;
        if (object.name == "AdjustColorFilter") {
            var colorFilter :AdjustColor = new AdjustColor();
            colorFilter.hue = getFilterDescVal(object, "hue", 0);
            colorFilter.saturation = getFilterDescVal(object, "saturation", 0);
            colorFilter.brightness = getFilterDescVal(object, "brightness", 0);
            colorFilter.contrast = getFilterDescVal(object, "contrast", 0);
            var mMatrix:Array = colorFilter.CalculateFinalFlatArray();
            filter = new ColorMatrixFilter(mMatrix);
        } else if (object.name == "BlurFilter") {
            filter = new BlurFilter(
                getFilterDescVal(object, "blurX", 5),
                getFilterDescVal(object, "blurY", 5),
                getFilterDescVal(object, "quality", 1)
            );
        } else if (object.name == "BevelFilter") {
            filter = new BevelFilter(
                getFilterDescVal(object, "distance", 5.0),
                getFilterDescVal(object, "angle", 45),
                parseInt(getFilterDescVal(object, "highlightColor", "#ffffff").substr(1), 16),
                getFilterDescVal(object, "highlightAlpha", 1.0),
                parseInt(getFilterDescVal(object, "shadowColor", "#000000").substr(1), 16),
                getFilterDescVal(object, "shadowAlpha", 1.0),
                getFilterDescVal(object, "blurX", 5),
                getFilterDescVal(object, "blurY", 5),
                getFilterDescVal(object, "strength", 1),
                getFilterDescVal(object, "quality", 1),
                getFilterDescVal(object, "type", "inner"),
                getFilterDescVal(object, "knockout", false)
            );
        } else if (object.name == "DropShadowFilter") {
            filter = new DropShadowFilter(
                getFilterDescVal(object, "distance", 5.0),
                getFilterDescVal(object, "angle", 45),
                parseInt(getFilterDescVal(object, "color", "#000000").substr(1), 16),
                getFilterDescVal(object, "alpha", 1.0),
                getFilterDescVal(object, "blurX", 5),
                getFilterDescVal(object, "blurY", 5),
                getFilterDescVal(object, "strength", 1),
                getFilterDescVal(object, "quality", 1),
                getFilterDescVal(object, "inner", false),
                getFilterDescVal(object, "knockout", false),
                getFilterDescVal(object, "hideObject", false)
            );
        } else if (object.name == "GlowFilter") {
            filter = new GlowFilter(
                parseInt(getFilterDescVal(object, "color", "#ff0000").substr(1), 16),
                getFilterDescVal(object, "alpha", 1),
                getFilterDescVal(object, "blurX", 5),
                getFilterDescVal(object, "blurY", 5),
                getFilterDescVal(object, "strength", 1),
                getFilterDescVal(object, "quality", 1),
                getFilterDescVal(object, "inner", false),
                getFilterDescVal(object, "knockout", false)
            );
        } else {
            // parsing for this filter type is unimplemented
        }

        return filter;
    }
    
    private function getFilterDescVal (object :Object, key :String, defaultVal :*) :* {
        if (key in object)
            return object[key];
        return defaultVal;
    }

    private var _descriptor :Object;
    private var _disp :DisplayObjectContainer;
    private var _clipRect :Rectangle;
    private var _clipRectXform :Array;
}
}
