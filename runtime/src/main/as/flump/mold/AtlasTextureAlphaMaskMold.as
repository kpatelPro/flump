//
// Flump 

package flump.mold {
    
import flash.display.BitmapData;
import flash.geom.Matrix;
import flash.utils.Dictionary;
import starling.textures.Texture;

/** @private */
public class AtlasTextureAlphaMaskMold
{
    public function isOpaqueParametric(paramX :Number, paramY :Number) :Boolean {
        // get coordinates in mask space
        var x :int = (paramX * (_width - 1));
        var y :int = (paramY * (_height - 1));

        // get the specific pixel's alpha data
        var bitIndex :uint = (y * _width) + x;
        var alpha :uint = _bits[int(bitIndex / 32)] & (1 << (31 - bitIndex % 32));

        // execute the test and return the result
        var opaque :Boolean = (alpha > 0);
        return opaque;
    }
    
    public static function fromBitmapData (bmd :BitmapData, alphaMaskQuality :Number) :AtlasTextureAlphaMaskMold {
        // calculate target representation dimensions
        var width :int;
        var height :int;
        if (alphaMaskQuality == 0) {
            throw('Attempt to create alphaMask with quality 0');
        } else if (alphaMaskQuality < 0) {
            // constant target size regardless of source dimensions / aspect ratio
            // i.e. quality -32 will create a 32x32 mask
            width = -alphaMaskQuality;
            height = -alphaMaskQuality;
        } else if (alphaMaskQuality <= 1) {
            // proportional representation (1 image pixel -> alphaMaskQuality mask bits)
            // (actually the same as alphaQuality = -1 / alphaQuality, above)
            width = Math.ceil(bmd.width * alphaMaskQuality);
            height = Math.ceil(bmd.height * alphaMaskQuality);
        } else { // (alphaMaskQuality > 1)
            // granular representation, (alphaMaskQuality image pixels -> 1 mask bit)
            // i.e. quality 2 will mask every 2x2 block of source pixels to 1 mask bit
            width = Math.ceil(bmd.width / alphaMaskQuality);
            height = Math.ceil(bmd.height / alphaMaskQuality);
        }
            
        // cap dimensions at scale 1
        width = Math.min(width, bmd.width);
        height = Math.min(height, bmd.height);
        
        // get pixel data from a scaled down image
        var pixelVector :Vector.<uint>;
        var smallBmd :BitmapData = new BitmapData(width, height, true, 0x000000);
        _s_hitTestScaleMatrix.setTo(width / bmd.width, 0, 0, height / bmd.height, 0, 0);
        smallBmd.draw(bmd, _s_hitTestScaleMatrix, null, null, null, true);
        pixelVector = smallBmd.getVector(smallBmd.rect);
        smallBmd.dispose();

        // generate mask from pixel vector
        return fromPixelVector(width, height, pixelVector);
    }
    
    public static function fromJSON (o :Object) :AtlasTextureAlphaMaskMold {
        var width :int = require(o, "width");
        var height :int = require(o, "height");
        var bitsString :String = require(o, "bitsString");
        return fromBitsString(width, height, bitsString);
    }

    public function toJSON (_:*) :Object {
        return {
            width: _width,
            height: _height,
            bitsString: _bitsString
        };
    }

    public function toXML () :XML {
        const json :Object = toJSON(null);
        return <texture width={_width} height={_height} bitsString={_bitsString}/>;
    }
    
    protected static function fromPixelVector(width :int, height :int, pixelVector :Vector.<uint>) :AtlasTextureAlphaMaskMold {
        // pad data to ensure adequate bits for compressed formats 
        // max(multiple of 32 length, multiple of 6 length)
        var originalDataLength :int = pixelVector.length;
        var minMaskDataLength :int = 32 * Math.ceil(originalDataLength / 32);
        var minStringDataLength :int = 6 * Math.ceil(originalDataLength / 6);
        var requiredDataLength :int = Math.max(minMaskDataLength, minStringDataLength);
        var requiredPadding :int = requiredDataLength - pixelVector.length;
        for (var p :int = 0; p < requiredPadding; ++p) {
            pixelVector.push(0);
        }
            
        // now loop over pixels and compact alpha values into bits 
        // every 32 -> bits Vector
        // every 6 -> base64 string
        var bits :Vector.<uint> = new Vector.<uint>();
        var bitsString :String = "";
        var charBitCount :uint = 0;
        var charBits :uint = 0;
        var maskBitCount :uint = 0;
        var maskBits :uint = 0;
        var pixel :uint;
        var alpha :uint;
        
        for (var ii :int = 0; ii < requiredDataLength; ++ii) {
            pixel = pixelVector[ii];
            alpha = pixel >> 24 & 0xFF;
            if (alpha > 0) {
                maskBits = (maskBits | 1);
                charBits = (charBits | 1);
            }
            if (++charBitCount == 6) {
                bitsString += intToBase64Char(charBits);
                charBitCount = 0;
                charBits = 0;
            }
            if (++maskBitCount == 32) {
                bits.push(maskBits);
                maskBitCount = 0;
                maskBits = 0;
            }
            maskBits = (maskBits << 1)
            charBits = (charBits << 1)
        }

        // create mold
        const mold :AtlasTextureAlphaMaskMold = new AtlasTextureAlphaMaskMold();
        mold._width = width;
        mold._height = height;
        mold._bits = bits;
        mold._bitsString = bitsString
        return mold;
    }

    protected static function fromBitsString(width :int, height :int, bitsString :String) :AtlasTextureAlphaMaskMold {
        // now loop over base64 string and recompact bits into mask
        
        // every base64 char -> 6 alpha bits
        // every 32 alpha bits -> bits Vector
        var bits :Vector.<uint> = new Vector.<uint>();
        var bitsStringLength :int = bitsString.length;
        var bitsStringIndex :uint = 0;
        var charBitCount :uint = 0;
        var charBits :uint = 0;
        var maskBitCount :uint = 0;
        var maskBits :uint = 0;
        var useBitCount :uint = 0;
        var useBits :uint = 0;

        do {
            // add bits
            useBitCount = Math.min(32 - maskBitCount, charBitCount);
            useBits = (charBits >> (charBitCount - useBitCount)); 
            maskBits = maskBits << useBitCount;
            maskBits = maskBits | useBits;
            maskBitCount += useBitCount;
            charBits = (charBits << (32 - (charBitCount - useBitCount))) >> (32 - (charBitCount - useBitCount));
            charBitCount -= useBitCount;
            
            // maybe stash mask bits
            if (maskBitCount == 32) {
                bits.push(maskBits);
                maskBitCount = 0;
                maskBits = 0;
            }
            
            // maybe get next char
            if ((charBitCount == 0) && (bitsStringIndex < bitsStringLength)) {
                charBitCount = 6;
                charBits = base64CharToInt(bitsString.charAt(bitsStringIndex));
                bitsStringIndex++;
            }
            
        }  while (charBitCount > 0);

        // any remaining bits are overflow and can be discarded
        maskBitCount = 0;
        maskBits = 0;

        // create mold
        const mold :AtlasTextureAlphaMaskMold = new AtlasTextureAlphaMaskMold();
        mold._width = width;
        mold._height = height;
        mold._bits = bits;
        mold._bitsString = bitsString
        return mold;
    }
    
    static private function intToBase64Char(input :int) :String {
        return _s_base64Chars.charAt(input);
    }

    static private function base64CharToInt(input :String) :int {
        return _s_base64Ints[input];
    }

    static private function buildBase64CharToIntTable() :void {
        if (_s_base64Ints)
            return;
            
        _s_base64Ints = new Dictionary();
        for (var ii :int = 0; ii < 64; ++ii) {
            var char :String = intToBase64Char(ii);
            _s_base64Ints[char] = ii;
        }
    }
    
    /* base64 conversion */
    static private var _s_base64Chars :String = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    static private var _s_base64Ints :Dictionary = null;
    /* reusable scale matrix */
    static private var _s_hitTestScaleMatrix :Matrix = new Matrix(1.0,0,0,1.0); 

    private var _width :int;
    private var _height :int;
    private var _bits :Vector.<uint>;
    private var _bitsString :String;
    
}
}
