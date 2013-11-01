package flump.display {

import flash.geom.Point;

import flump.mold.AtlasTextureAlphaMaskMold;

import starling.display.DisplayObject;
import starling.display.Image;
import starling.textures.Texture;

public class ImageCreator
    implements SymbolCreator
{
    public var texture :Texture;
    public var origin :Point;
    public var symbol :String;
    public var alphaMask :AtlasTextureAlphaMaskMold

    public function ImageCreator (texture :Texture, origin :Point, symbol :String, alphaMask :AtlasTextureAlphaMaskMold) {
        this.texture = texture;
        this.origin = origin;
        this.symbol = symbol;
        this.alphaMask = alphaMask;
    }

    public function create (library :Library) :DisplayObject {
        const image :Image = alphaMask ? (new ImageWithAlphaMask(texture, alphaMask)) : (new Image(texture));
        image.pivotX = origin.x;
        image.pivotY = origin.y;
        image.name = symbol;
        return image;
    }
}
}
