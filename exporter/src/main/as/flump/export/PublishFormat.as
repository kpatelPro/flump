//
// Flump - Copyright 2013 Flump Authors

package flump.export {

import flash.filesystem.File;
import flash.utils.Dictionary;

import flump.xfl.XflLibrary;
import flump.Portrait;

public class PublishFormat
{
    public function PublishFormat (destDir :File, lib :XflLibrary, conf :ExportConf) {
        _lib = lib;
        _destDir = destDir;
        _conf = conf;
    }

    public function get modified () :Boolean { throw new Error("Must be implemented by a subclass"); }

    public function publish () :void { throw new Error("Must be implemented by a subclass"); }

    protected function createAtlases (prefix :String = "") :Vector.<Atlas> {
        const packer :TexturePacker = TexturePacker.withLib(_lib)
            .baseScale(_conf.scale)
            .borderSize(_conf.textureBorder)
            .maxAtlasSize(_conf.maxAtlasSize)
            .optimizeForSpeed(_conf.optimize == ExportConf.OPTIMIZE_SPEED)
            .quality(_conf.quality)
            .filenamePrefix(prefix);

        var atlases :Vector.<Atlas> = packer.scaleFactor(1).createAtlases(); // 1x atlases

        // additional scales
        for each (var scaleFactor :int in _conf.additionalScaleFactors) {
            atlases = atlases.concat(packer.scaleFactor(scaleFactor).createAtlases());
        }

        return atlases;
    }

    protected function createPortraits () :Dictionary {
        
        // fill portraits with a portrait for each boundsSymbolName
        var portraits:Dictionary = new Dictionary();
        for each (var boundsSymbolName :String in Portrait.kPortraitBoundsNames) {
            // for each bounds name, search movies for bounds until one is found
            for each (var movieSymbolName :String in Portrait.kPortraitMovieNames) {
                var portrait :Portrait = Portrait.fromMovieAndBounds(_lib, movieSymbolName, boundsSymbolName);
                // if found, add portrait to dictionary and move on to next boundsSymbolName
                if (portrait) {
                    var portraitName :String = boundsSymbolName;
                    var nameParts :Array = boundsSymbolName.split('_');
                    if (nameParts.length > 1) {
                        nameParts.shift();
                        portraitName = nameParts.join('_');
                    }
                    portraits[portraitName] = portrait;
                    break;
                }
            }
        }
        
        return portraits;
    }

    protected var _lib :XflLibrary;
    protected var _destDir :File;
    protected var _conf :ExportConf;

}
}
