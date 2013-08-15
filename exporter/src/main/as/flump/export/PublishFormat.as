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
        
        // static
        const symbolNames:Array = ['scale', 'idle', 'idle0'];
        const boundsSymbolNames:Array = ['bounds_portrait'];
        
        // fill portraits with a portrait for each boundsSymbolName
        var portraits:Dictionary = new Dictionary();
        for each (var boundsSymbolName:String in boundsSymbolNames) {
            for each (var symbolName:String in symbolNames) {
                var portrait:Portrait = Portrait.fromSymbolAndBounds(_lib, symbolName, boundsSymbolName);
                if (portrait) {
                    portraits[boundsSymbolName] = portrait;
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
