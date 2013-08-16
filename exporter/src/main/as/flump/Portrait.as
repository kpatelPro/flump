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

public class Portrait
{
    public static function fromDescriptor (lib :XflLibrary, descriptor :Object) :Portrait {
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
        var clipRectXform :Array = [1, 1, 0, 0]; // identity transform
        // if clipping with a bounds name, set the clip values
        if (descriptor.clipBoundsName) {
            // get bounds
            clipRect = Bounds.getBoundsForBoundsName(lib, descriptor.clipBoundsName);
            if (!clipRect) return null;
            
            // get translation matrix
            clipRectXform = Bounds.getBoundsPortraitXform(mold, descriptor.clipBoundsName);
            if (!clipRectXform) return null;
        }
        // otherwise no clipping

        // create portrait
        return new Portrait(mc, clipRect, clipRectXform);
    }
    
    public function Portrait (disp :DisplayObjectContainer, clipRect :Rectangle, clipRectXform :Array) {
        _disp = disp;
        _clipRect = clipRect ? clipRect : _disp.getBounds(_disp);
        _clipRectXform = clipRectXform;
    }
    
    public function toBitmapData () :BitmapData {
        
        // parse xform parameters
        var scaleX :Number = _clipRectXform[0];
        var scaleY :Number = _clipRectXform[1];
        var offsetX :Number = _clipRectXform[2];
        var offsetY :Number = _clipRectXform[3];
        
        // calculate final clip bounds
        var clipRect :Rectangle = new Rectangle(
            _clipRect.x * scaleX, 
            _clipRect.y * scaleY, 
            _clipRect.width * scaleX, 
            _clipRect.height * scaleY); 
        clipRect.offset(offsetX, offsetY);
        
        // render with vector renderer
        var m :Matrix = new Matrix();
        m.translate( -(_disp.x + clipRect.x), -(_disp.y + clipRect.y));
        clipRect.offset( -clipRect.x, -clipRect.y);
        
        // render!
        var bmd :BitmapData = new BitmapData(Math.ceil(clipRect.width), Math.ceil(clipRect.height), true, 0x00);
        bmd.drawWithQuality(_disp, m, null, null, clipRect, true, StageQuality.BEST);

        return bmd;
    }

    private var _disp :DisplayObjectContainer;
    private var _clipRect :Rectangle;
    private var _clipRectXform :Array;
}
}
