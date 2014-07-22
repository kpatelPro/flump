//
// Flump - Copyright 2013 Flump Authors

package flump.export {

import flash.filesystem.File;
import flash.utils.ByteArray;
import flash.utils.IDataOutput;

import deng.fzip.FZip;
import deng.fzip.FZipFile;

import flump.display.LibraryLoader;
import flump.mold.AMF;
import flump.xfl.XflLibrary;

public class AMFZipFormat extends JSONZipFormat
{
    public static const NAME :String = "AMFZip";

    public function AMFZipFormat (destDir :File, lib :XflLibrary, conf :ExportConf) {
        AMF.registerClassAliases();
        super(destDir, lib, conf);
    }

    override public function publish() :void {
        const zip :FZip = new FZip();

        function addToZip(name :String, contentWriter :Function) :void {
            const bytes :ByteArray = new ByteArray();
            contentWriter(bytes);
            zip.addFile(name, bytes);
        }

        const atlases :Vector.<Atlas> = createAtlases();
        for each (var atlas :Atlas in atlases) {
            addToZip(atlas.filename, function (b :ByteArray) :void { AtlasUtil.writePNG(atlas, b); });
        }
        addToZip(LibraryLoader.LIBRARY_LOCATION_AMF, function (b :ByteArray) :void {
            b.writeObject(_lib.toMold(atlases, _conf));
        });
        addToZip(LibraryLoader.MD5_LOCATION,
            function (b :ByteArray) :void { b.writeUTFBytes(_lib.md5); });
        addToZip(LibraryLoader.VERSION_LOCATION,
            function (b :ByteArray) :void { b.writeUTFBytes(LibraryLoader.VERSION); });

        Files.write(outputFile, function (out :IDataOutput) :void {
            zip.serialize(out, /*includeAdler32=*/true);
        });
    }

}
}
