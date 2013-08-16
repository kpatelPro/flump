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

public class Bounds
{
    // boundsSymbols by library
    // The list of boundsSymbol library items specified in the ProjectConfig associated with this lib
    static public function setBoundsSymbolsForLibrary(lib :XflLibrary, boundsSymbols :Array) :void {
        _s_boundsSymbolsByLibrary[lib] = boundsSymbols;
    }
    static public function getBoundsSymbolsForLibrary(lib :XflLibrary) :Array {
        if (lib in _s_boundsSymbolsByLibrary) {
            return _s_boundsSymbolsByLibrary[lib];
        }
        return null;
    }
    
    // Bounds by boundsName
    // The rectangular bounds of each boundsSymbol library item specified in the ProjectConfig
    static public function setBoundsForBoundsName (lib :XflLibrary, boundsName :String, bounds :Rectangle) :void {
        if (!(lib in _s_boundsByBoundsName))
            _s_boundsByBoundsName[lib] = new Dictionary();
        _s_boundsByBoundsName[lib][boundsName] = bounds;
    }
    static public function getBoundsForBoundsName(lib :XflLibrary, boundsName :String) :Rectangle {
        if (lib in _s_boundsByBoundsName) {
            if (boundsName in _s_boundsByBoundsName[lib]) {
                return _s_boundsByBoundsName[lib][boundsName];
            }
        }
        return null;
    }
    
    // Bounds transforms by MovieMold
    // The transform of a boundsSymbol instance within a specific Movie
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

    // internal 
    static private var _s_boundsSymbolsByLibrary:Dictionary = new Dictionary();
    static private var _s_boundsByBoundsName :Dictionary = new Dictionary();
    static private var _s_boundsPortraitXformByMovieMold :Dictionary = new Dictionary(true);
}
}
