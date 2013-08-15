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
    public static const kPortraitMovieNames:Array = ['idle', 'idle0', 'scale'];
    public static const kPortraitBoundsNames:Array = ['bounds_portrait', 'bounds_full_body'];
    
    public static function fromMovieAndBounds (lib :XflLibrary, movieName :String, boundsName :String) :Portrait {

        // get MovieMold
        if (!lib.hasItem(movieName)) return null;
        const mold :MovieMold = lib.getItem(movieName);
        if (!mold) return null;
        
        // get translation matrix
        const xform :Array = getBoundsPortraitXform(mold, boundsName);
        if (!xform) return null;
        
        // get bounds
        const bounds :Rectangle = getBoundsForBoundsName(boundsName);
        if (!bounds) return null;
        
        // get symbol movieclip
        const klass :Class = Class(lib.swf.getSymbol(movieName));
        if (!klass) return null;
        const clip :MovieClip = MovieClip(new klass());
        if (!clip) return null;

        // create portrait with these parameters
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
        var boundsRect :Rectangle = getBoundsForBoundsName(_boundsName);
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

    // lookup table for bounds_portrait matrix transforms by MovieMold
    static private var _s_boundsPortraitXformByMovieMold :Dictionary = new Dictionary(true);
    static public function setBoundsPortraitXform (movie :MovieMold, boundsName :String, xform :Array) :void {
        if (!(movie in _s_boundsPortraitXformByMovieMold))
            _s_boundsPortraitXformByMovieMold[movie] = new Dictionary();
        _s_boundsPortraitXformByMovieMold[movie][boundsName] = xform;
    }
    static public function getBoundsPortraitXform (movie :MovieMold, boundsName :String) :Array {
        if (movie in _s_boundsPortraitXformByMovieMold) {
            if (boundsName in _s_boundsPortraitXformByMovieMold[movie]) {
                return _s_boundsPortraitXformByMovieMold[movie][boundsName];
            }
        }
        return null;
    }
    
    // lookup table for bounds by boundsName
    static private var _s_boundsByBoundsName :Dictionary = new Dictionary();
    static public function setBoundsForBoundsName (boundsName :String, bounds :Rectangle) :void {
        _s_boundsByBoundsName[boundsName] = bounds;
    }
    static public function getBoundsForBoundsName(boundsName :String) :Rectangle {
        return (boundsName in _s_boundsByBoundsName) ? _s_boundsByBoundsName[boundsName] : null;
    }
    
}
}
