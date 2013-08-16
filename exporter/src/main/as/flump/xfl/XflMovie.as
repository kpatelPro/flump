//
// Flump - Copyright 2013 Flump Authors

package flump.xfl {

import flash.geom.Matrix;
import flash.utils.Dictionary;
import flump.Portrait;

import com.threerings.util.Set;
import com.threerings.util.Sets;
import com.threerings.util.XmlUtil;

import flump.mold.KeyframeMold;
import flump.mold.LayerMold;
import flump.mold.MovieMold;

public class XflMovie
{
    use namespace xflns;

    /** Returns true if the given movie symbol is marked for "Export for ActionScript" */
    public static function isExported (xml :XML) :Boolean {
        return XmlUtil.hasAttr(xml, "linkageClassName");
    }

    /** Returns the library name of the given movie */
    public static function getName (xml :XML) :String {
        return XmlUtil.getStringAttr(xml, "name");
    }

    /** Return a Set of all the symbols this movie references. */
    public static function getSymbolNames (mold :MovieMold) :Set {
        var names :Set = Sets.newSetOf(String);
        for each (var layer :LayerMold in mold.layers) {
            if (!layer.flipbook) {
                for each (var kf :KeyframeMold in layer.keyframes) {
                    if (kf.ref != null) names.add(kf.ref);
                }
            }
        }
        return names;
    }

    public static function parse (lib :XflLibrary, xml :XML) :MovieMold {
        const movie :MovieMold = new MovieMold();
        const name :String = getName(xml);
        const symbol :String = XmlUtil.getStringAttr(xml, "linkageClassName", null);
        movie.id = lib.createId(movie, name, symbol);
        const location :String = lib.location + ":" + movie.id;

        const layerEls :XMLList = xml.timeline.DOMTimeline[0].layers.DOMLayer;
        if (XmlUtil.getStringAttr(layerEls[0], "name") == "flipbook") {
            movie.layers.push(XflLayer.parse(lib, location, layerEls[0], true, null));
            if (symbol == null) {
                lib.addError(location, ParseError.CRIT, "Flipbook movie '" + movie.id + "' not exported");
            }
            for each (var kf :KeyframeMold in movie.layers[0].keyframes) {
                kf.ref = movie.id + "_flipbook_" + kf.index;
            }
        } else {
            for each (var layerEl :XML in layerEls) {
                var layerType :String = XmlUtil.getStringAttr(layerEl, "layerType", "");
                if (layerType == "folder") {
                    // ignore
                } else if (layerType == "guide") {
                    // check for Portrait bounds xform
                    lib.incSuppressingErrors();
                    try {
                        var guideLayer:LayerMold = XflLayer.parse(lib, location, layerEl, false, null);
                        var guideKeyframe:KeyframeMold = guideLayer.keyframes[0];
                        if (lib.getBoundsSymbols().indexOf(guideKeyframe.ref) >= 0) {
                            lib.setBoundsSymbolXformForMovie(
                                guideKeyframe.ref,
                                movie, 
                                [guideKeyframe.scaleX, guideKeyframe.scaleY, guideKeyframe.x, guideKeyframe.y]
                            )
                        }
                    } catch (e :Error) {}
                    lib.decSuppressingErrors();
                } else if (lib.getBoundsSymbols().indexOf(name) >= 0) {
                    // parse Portrait bounds
                    lib.incSuppressingErrors();
                    try {
                        XflLayer.parse(lib, location, layerEl, false, name);
                    } catch (e :Error) {}
                    lib.decSuppressingErrors();
                } else {
                    movie.layers.unshift(XflLayer.parse(lib, location, layerEl, false, null));
                }
            }
        }
        movie.fillLabels();

        if (movie.layers.length == 0) {
            lib.addError(location, ParseError.CRIT, "Movies must have at least one layer");
        }

        return movie;
    }

    // lookup table for filters associated with a given flipbook MovieMold
    static private var _s_filtersByFlipbookMovieMold :Dictionary = new Dictionary(true);
    static public function setFiltersForFlipbook(movie :MovieMold, filters :Array) :void {
        _s_filtersByFlipbookMovieMold[movie] = filters;
    }
    static public function getFiltersForFlipbook(movie :MovieMold) :Array {
        return (movie in _s_filtersByFlipbookMovieMold) ? _s_filtersByFlipbookMovieMold[movie] : [];
    }

}
}
