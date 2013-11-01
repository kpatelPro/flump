package flump.display {

import flash.geom.Point;

import flump.mold.AtlasTextureAlphaMaskMold;

import starling.display.DisplayObject;
import starling.display.Image;
import starling.textures.Texture;

public class ImageWithAlphaMask extends Image {
    public var alphaMask :AtlasTextureAlphaMaskMold;
    public var textureWidth :int;
    public var textureHeight :int;

    public function ImageWithAlphaMask (texture :Texture, alphaMask :AtlasTextureAlphaMaskMold) {
        this.alphaMask = alphaMask;
        this.textureWidth = texture.width;
        this.textureHeight = texture.height;
        super(texture);
    }

	override public function hitTest (localPoint:flash.geom.Point, forTouch:Boolean = false) : DisplayObject {
        if (!super.hitTest(localPoint, forTouch))
            return null;
            
        if (alphaMask.isOpaqueParametric(localPoint.x / textureWidth, localPoint.y / textureHeight))
            return this;
            
        return null;
    }
}

}
