// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package tests.rendering;

import starling.rendering.VertexDataFormat;
import utest.Assert;
import utest.Test;

class VertexDataFormatTest extends Test
{
	@:final private static var STD_FORMAT:String = "position:float2, texCoords:float2, color:bytes4";

	public function testFormatParsing():Void
	{
		var vdf:VertexDataFormat = VertexDataFormat.fromString(STD_FORMAT);

		Assert.equals( 2, vdf.getSizeIn32Bits("position"));
		Assert.equals( 8, vdf.getSize("position"));
		Assert.equals( 2, vdf.getSizeIn32Bits("texCoords"));
		Assert.equals( 8, vdf.getSize("texCoords"));
		Assert.equals( 1, vdf.getSizeIn32Bits("color"));
		Assert.equals( 4, vdf.getSize("color"));
		Assert.equals( 5, vdf.vertexSizeIn32Bits);
		Assert.equals(20, vdf.vertexSize);

		Assert.equals("float2", vdf.getFormat("position"));
		Assert.equals("float2", vdf.getFormat("texCoords"));
		Assert.equals("bytes4", vdf.getFormat("color"));

		Assert.equals( 0, vdf.getOffsetIn32Bits("position"));
		Assert.equals( 0, vdf.getOffset("position"));
		Assert.equals( 2, vdf.getOffsetIn32Bits("texCoords"));
		Assert.equals( 8, vdf.getOffset("texCoords"));
		Assert.equals( 4, vdf.getOffsetIn32Bits("color"));
		Assert.equals(16, vdf.getOffset("color"));

		Assert.equals(STD_FORMAT, vdf.formatString);
	}

	
	public function testEmpty():Void
	{
		var vdf:VertexDataFormat = VertexDataFormat.fromString(null);
		Assert.equals("", vdf.formatString);
		Assert.equals(0, vdf.numAttributes);
	}

	
	public function testCaching():Void
	{
		var formatA:String = "  position :float2  ,color:  bytes4   ";
		var formatB:String = "position:float2,color:bytes4";

		var vdfA:VertexDataFormat = VertexDataFormat.fromString(formatA);
		var vdfB:VertexDataFormat = VertexDataFormat.fromString(formatB);

		Assert.equals(vdfA, vdfB);
	}

	
	public function testNormalization():Void
	{
		var format:String = "   position :float2  ,color:  bytes4   ";
		var normalizedFormat:String = "position:float2, color:bytes4";
		var vdf:VertexDataFormat = VertexDataFormat.fromString(format);
		Assert.equals(normalizedFormat, vdf.formatString);
	}

	
	public function testExtend():Void
	{
		var formatString:String = "position:float2";
		var baseFormat:VertexDataFormat = VertexDataFormat.fromString(formatString);
		var exFormat:VertexDataFormat = baseFormat.extend("color:float4");
		Assert.equals("position:float2, color:float4", exFormat.formatString);
		Assert.equals(2, exFormat.numAttributes);
		Assert.equals("float2", exFormat.getFormat("position"));
		Assert.equals("float4", exFormat.getFormat("color"));
	}

	public function testInvalidFormatString():Void
	{
		Assert.raises(function():Void
		{
			VertexDataFormat.fromString("color:double2");
		}, openfl.errors.Error);
	}

	public function testInvalidFormatString2():Void
	{
		Assert.raises(function():Void
		{
			VertexDataFormat.fromString("color.float4");
		}, openfl.errors.Error);
	}
}