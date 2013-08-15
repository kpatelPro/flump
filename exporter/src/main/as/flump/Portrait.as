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

import flump.executor.load.LoadedSwf;
import flump.xfl.XflLibrary;
import flump.xfl.XflMovie;

import flump.mold.MovieMold;

import com.threerings.display.DisplayUtil;

public class Portrait
{
    public static function fromSymbolAndBounds (lib :XflLibrary, symbolName :String, boundsName :String) :Portrait {

        // get MovieMold
        const mold :MovieMold = lib.getItem(symbolName);
        if (!mold) return null;
        
        // get translation matrix
        const xform :Array = XflMovie.getBoundsPortraitXform(mold);
        if (!xform) return null;
        
        // get symbol movieclip
        const klass :Class = Class(lib.swf.getSymbol(symbolName));
        if (!klass) return null;
        const clip :MovieClip = MovieClip(new klass());
        if (!clip) return null;
        
        // search for parent of boundsName within symbol
        return new Portrait(clip, xform, boundsName);
    }

    public function Portrait (disp :DisplayObjectContainer, xform :Array, boundsName :String) {
        _disp = disp;
        _xform = xform;
        _boundsName = boundsName;
    }
    
    public function toBitmapData () :BitmapData {
        
        // parse xform parameters
        var scaleX :Number = _xform[0];
        var scaleY :Number = _xform[1];
        var offsetX :Number = _xform[2];
        var offsetY :Number = _xform[3];
        
        // calculate final clip bounds
        var boundsRect :Rectangle = new Rectangle(-118.55, -118.55, 237.05, 237.05);
        var clipRect :Rectangle = new Rectangle(
            boundsRect.x * scaleX, 
            boundsRect.y * scaleY, 
            boundsRect.width * scaleX, 
            boundsRect.height * scaleY); 
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
    private var _xform :Array;
    private var _boundsName :String;
    
}
}
