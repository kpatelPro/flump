//
// Flump - Copyright 2013 Flump Authors

package flump.mold {

import flash.net.registerClassAlias;
    
/** @private */
public class AMF
{
    public static function registerClassAliases() :void {
        registerClassAlias("flump.mold.AtlasMold", flump.mold.AtlasMold);
        registerClassAlias("flump.mold.AtlasTextureMold", flump.mold.AtlasTextureMold);
        registerClassAlias("flump.mold.KeyframeMold", flump.mold.KeyframeMold);
        registerClassAlias("flump.mold.LayerMold", flump.mold.LayerMold);
        registerClassAlias("flump.mold.LibraryMold", flump.mold.LibraryMold);
        registerClassAlias("flump.mold.MovieMold", flump.mold.MovieMold);
        registerClassAlias("flump.mold.TextureGroupMold", flump.mold.TextureGroupMold);        
    }
}
}
