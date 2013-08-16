//
// Flump - Copyright 2013 Ken Patel

package flump {

import flash.display.BitmapData;
import flash.display.DisplayObject;
import flash.display.DisplayObjectContainer;
import flash.display.MovieClip;
import flash.display.Sprite;
import flash.display.StageQuality;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.utils.Dictionary;

import flump.executor.load.LoadedSwf;
import flump.xfl.XflLibrary;
import flump.xfl.XflMovie;

import flump.mold.MovieMold;

import com.threerings.display.DisplayUtil;

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
        
        if (_clipRect) {
            return toBitmapDataWithClip();
        } else {
            return toBitmapDataNoClip();
        }
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
    
    private var _descriptor :Object;
    private var _disp :DisplayObjectContainer;
    private var _clipRect :Rectangle;
    private var _clipRectXform :Array;
}
}
