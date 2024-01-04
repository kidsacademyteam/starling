// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.textures;

import openfl.display.StageQuality;
import haxe.Timer;
import openfl.display.BitmapData;
import openfl.display3D.textures.TextureBase;
import openfl.errors.ArgumentError;
import openfl.errors.Error;
import openfl.events.ErrorEvent;
import openfl.events.Event;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.utils.ByteArray;

import starling.core.Starling;
import starling.utils.MathUtil;

/** @private
 *
 *  A concrete texture that wraps a <code>Texture</code> base.
 *  For internal use only. */
@:allow(starling) class ConcretePotTexture extends ConcreteTexture
{
    private var _textureReadyCallback:ConcreteTexture->Void;

    private static var sMatrix:Matrix = new Matrix();
    private static var sRectangle:Rectangle = new Rectangle();
    private static var sOrigin:Point = new Point();
    private static var sAsyncUploadEnabled:Bool = false;

    /** Creates a new instance with the given parameters. */
    private function new(base:openfl.display3D.textures.Texture, format:String,
                         width:Int, height:Int, mipMapping:Bool,
                         premultipliedAlpha:Bool,
                         optimizedForRenderTexture:Bool=false, scale:Float=1)
    {
        super(base, format, width, height, mipMapping, premultipliedAlpha,
              optimizedForRenderTexture, scale);

        if (width != MathUtil.getNextPowerOfTwo(width))
            throw new ArgumentError("width must be a power of two");

        if (height != MathUtil.getNextPowerOfTwo(height))
            throw new ArgumentError("height must be a power of two");
    }

    /** @inheritDoc */
    override public function dispose():Void
    {
        base.removeEventListener(Event.TEXTURE_READY, onTextureReady);
        super.dispose();
    }

    /** @inheritDoc */
    override private function createBase():TextureBase
    {
        return Starling.current.context.createTexture(
                Std.int(nativeWidth), Std.int(nativeHeight), format, optimizedForRenderTexture);
    }

    /** @inheritDoc */
    override public function uploadBitmapData(data:BitmapData, async:ConcreteTexture->Void=null):Void
    {
        var buffer:BitmapData = null;
        var isAsync:Bool = async != null;

        if (isAsync)
            _textureReadyCallback = async;

        if (data.width != nativeWidth || data.height != nativeHeight)
        {
            buffer = new BitmapData(Std.int(nativeWidth), Std.int(nativeHeight), true, 0);
            buffer.copyPixels(data, data.rect, sOrigin);
            data = buffer;
        }

        #if html5
        upload(data, 0, mipMapping, isAsync);
        #else
        upload(data, 0, isAsync);

        if (mipMapping && data.width > 1 && data.height > 1)
        {
            var currentWidth:Int  = data.width  >> 1;
            var currentHeight:Int = data.height >> 1;
            var level:Int = 1;
            var canvas:BitmapData = new BitmapData(currentWidth, currentHeight, true, 0);
            var bounds:Rectangle = sRectangle;
            var matrix:Matrix = sMatrix;
            matrix.setTo(0.5, 0.0, 0.0, 0.5, 0.0, 0.0);

            while (currentWidth >= 1 || currentHeight >= 1)
            {
                bounds.setTo(0, 0, currentWidth, currentHeight);
                canvas.fillRect(bounds, 0);
                canvas.drawWithQuality(data, matrix, null, null, null, false, StageQuality.BEST);
                upload(canvas, level++, false, false); // only level 0 supports async
                matrix.scale(0.5, 0.5);
                currentWidth  = currentWidth  >> 1;
                currentHeight = currentHeight >> 1;
            }

            canvas.dispose();
        }
        #end

        if (buffer != null) buffer.dispose();

        setDataUploaded();
    }

    override public function uploadFromByteArray(data:ByteArray, generateMipMaps:Bool = false, async:ConcreteTexture->Void=null):Void
    {
        var isAsync:Bool = async != null;

        if (isAsync)
            _textureReadyCallback = async;

        uploadByteArray(data, 0, generateMipMaps, isAsync);

        setDataUploaded();
    }

    /** @inheritDoc */
    override private function get_isPotTexture():Bool { return true; }

    /** @inheritDoc */
    override public function uploadAtfData(data:ByteArray, offset:Int = 0, async:ConcreteTexture->Void = null):Void
    {
        data.endian = BIG_ENDIAN;
        var isAsync:Bool = async != null;

        if (isAsync)
        {
            _textureReadyCallback = async;
            base.addEventListener(Event.TEXTURE_READY, onTextureReady);
        }

        potBase.uploadCompressedTextureFromByteArray(data, offset, isAsync);
        setDataUploaded();
    }

    private function upload(source:BitmapData, mipLevel:UInt, isGenerateMipMaps:Bool, isAsync:Bool):Void
    {
        if (isAsync)
        {
            uploadAsync(source, mipLevel, isGenerateMipMaps);
            base.addEventListener(Event.TEXTURE_READY, onTextureReady);
            base.addEventListener(ErrorEvent.ERROR, onTextureReady);
        }
        else
        {
            potBase.uploadFromBitmapData(source, mipLevel, isGenerateMipMaps);
        }
    }

    private function uploadByteArray(source:ByteArray, mipLevel:UInt, isGenerateMipMaps:Bool, isAsync:Bool):Void
    {
        if (isAsync)
        {
            uploadAsyncByteArray(source, mipLevel, isGenerateMipMaps);
            base.addEventListener(Event.TEXTURE_READY, onTextureReady);
            base.addEventListener(ErrorEvent.ERROR, onTextureReady);
        }
        else
        {
            potBase.uploadFromByteArray(source, 0, mipLevel, isGenerateMipMaps);
        }
    }

    private function uploadAsyncByteArray(source:ByteArray, mipLevel:UInt, isGenerateMipMaps:Bool):Void
    {
        if (sAsyncUploadEnabled)
        {
            var method = Reflect.field(base, "uploadFromByteArray");
            try { Reflect.callMethod(base, method, [source, mipLevel, isGenerateMipMaps]); }
            catch (error:Error)
            {
                if (error.errorID == 3708 || error.errorID == 1069)
                    sAsyncUploadEnabled = false;
                else
                    throw error;
            }
        }

        if (!sAsyncUploadEnabled)
        {
            Timer.delay(function () {
                base.dispatchEvent(new Event(Event.TEXTURE_READY));
            }, 1);
            potBase.uploadFromByteArray(source, 0, mipLevel, isGenerateMipMaps);
        }
    }

    private function uploadAsync(source:BitmapData, mipLevel:UInt, isGenerateMipMaps:Bool):Void
    {
        if (sAsyncUploadEnabled)
        {
            var method = Reflect.field(base, "uploadFromBitmapDataAsync");
            try { Reflect.callMethod(base, method, [source, mipLevel, isGenerateMipMaps]); }
            catch (error:Error)
            {
                if (error.errorID == 3708 || error.errorID == 1069)
                    sAsyncUploadEnabled = false;
                else
                    throw error;
            }
        }

        if (!sAsyncUploadEnabled)
        {
            Timer.delay(function () {
                base.dispatchEvent(new Event(Event.TEXTURE_READY));
            }, 1);
            potBase.uploadFromBitmapData(source, mipLevel, isGenerateMipMaps);
        }
    }

    private function onTextureReady(event:Event):Void
    {
        base.removeEventListener(Event.TEXTURE_READY, onTextureReady);
        base.removeEventListener(ErrorEvent.ERROR, onTextureReady);

        if(_textureReadyCallback != null)
            _textureReadyCallback(this);
        _textureReadyCallback = null;
    }

    private var potBase(get, never):openfl.display3D.textures.Texture;
    private function get_potBase():openfl.display3D.textures.Texture
    {
        return cast base;
    }

    /** @private */
    @:allow(starling) private static var asyncUploadEnabled(get, set):Bool;
    private static function get_asyncUploadEnabled():Bool { return sAsyncUploadEnabled; }
    private static function set_asyncUploadEnabled(value:Bool):Bool { return sAsyncUploadEnabled = value; }
}
