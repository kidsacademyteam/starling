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

/** A class that provides constant values for the possible smoothing algorithms of a texture. */ 
class TextureSmoothing
{
    /** No smoothing, also called "Nearest Neighbor". Pixels will scale up as big rectangles. */
    public static inline var NONE:String      = "none";
    
    /** Bilinear filtering. Creates smooth transitions between pixels. */
    public static inline var BILINEAR:String  = "bilinear";
    
    /** Trilinear filtering. Highest quality by taking the next mip map level into account. */
    public static inline var TRILINEAR:String = "trilinear";

    public static inline var ANISOTROPIC2X:String = "anisotropic2x";
    public static inline var ANISOTROPIC4X:String = "anisotropic4x";
    public static inline var ANISOTROPIC8X:String = "anisotropic8x";
    public static inline var ANISOTROPIC16X:String = "anisotropic16x";

    /** Determines whether a smoothing value is valid. */
    public static function isValid(smoothing:String):Bool
    {
        return smoothing == NONE || smoothing == BILINEAR || smoothing == TRILINEAR
        || smoothing == ANISOTROPIC2X|| smoothing == ANISOTROPIC4X || smoothing == ANISOTROPIC8X || smoothing == ANISOTROPIC16X;
    }
}