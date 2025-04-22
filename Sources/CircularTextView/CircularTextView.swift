import SwiftUI



public extension UnitPoint
{
	init(vertical:VerticalAlignment,horzional:HorizontalAlignment)
	{
		switch (vertical,horzional)
		{
			case(.top,.leading):	self = UnitPoint.topLeading
			case(.top,.center):		self = UnitPoint.top
			case(.top,.trailing):	self = UnitPoint.topTrailing
			case(.center,.leading):	self = UnitPoint.leading
			case(.center,.center):	self = UnitPoint.center
			case(.center,.trailing):	self = UnitPoint.trailing
			case(.bottom,.leading):	self = UnitPoint.bottomLeading
			case(.bottom,.center):	self = UnitPoint.bottom
			case(.bottom,.trailing):	self = UnitPoint.bottomTrailing
				
				//	shouldnt occur...
			case (_, _):	self = UnitPoint.center
		}
		
	}
}

//	style text in usual way on top of this view
public struct CircularTextView: View 
{
	//	read current font
	@Environment(\.font) var font
	
	var text : String
	
	var startingAngle : Angle
	var clockwise = true
	
	//	align letter rotations at the top, bottom or middle
	let kerningAlignment : VerticalAlignment
	var debugTextAlignment = false
	
	public init(_ text:String,startingAngle:Angle = .degrees(0), kerningAlignment:VerticalAlignment = .center,clockwise:Bool=true,debug:Bool=false)
	{
		self.text = text
		self.clockwise = clockwise
		self.startingAngle = startingAngle
		self.kerningAlignment = kerningAlignment
		self.debugTextAlignment = debug
	}
	
	func GetDebugColour(_ index:Int) -> Color
	{
		let colours : [Color] = [.red,.orange,.yellow,.green,.cyan,.blue,.purple,.pink]
		let colour = colours[ index % colours.count]
		return colour.opacity( 0.7 )
	}
	
	public var body: some View 
	{
		//	for future expansion to render views in an arc
		let texts : [Text] = text.enumerated().map
		{
			char in
			Text(String(char.element))
				.font(font)
		}
		
		Canvas 
		{
			context, canvasSize in
			let viewRadius = min( canvasSize.width, canvasSize.height ) / 2.0
			
			//	how many pixels around the circumference we've moved
			var circumferenceX = 0.0
			
			//	make all operations start at the center
			context.translateBy(x: canvasSize.width/2.0, y: canvasSize.height/2.0)
			
			for characterIndex in 0..<texts.count
			{
				let textElement = texts[characterIndex]
				let resolved = context.resolve(textElement)
				let charSize = resolved.measure(in: CGSize(width: 900, height: 900))
				//print("Char \(char.element) height = \(charSize.height)")
				let letterHeight = charSize.height
				
				//	height is consistent for whole string
				var kerningAlignmentLetterHeight : Double {
					switch kerningAlignment
					{
						case .top:	return 0.0
						case .center:	return 0.5
						case .bottom:	return 1.0
						case _:	return 0.5
					}
				}
				
				let baselineRadius = viewRadius - (letterHeight*kerningAlignmentLetterHeight)
				
				//	move x pos across so we have the center
				//	but not if we're the first so left side of character hits the starting angle
				if characterIndex > 0
				{
					circumferenceX += charSize.width * 0.5
				}
				
				//	convert our pos along [baseline] circumference to angle
				let circumference = (2.0 * .pi * baselineRadius)
				//	as 0...1
				let normalisedPosAlongCircumference = (circumferenceX / circumference) * (clockwise ? 1.0 : -1.0)
				//	0..1 to angle
				var angleOfChar = Angle.degrees( normalisedPosAlongCircumference * 360.0 )
				
				//	expecting this to be -startingAngle, but as Y is flipped, we add
				angleOfChar += clockwise ? startingAngle : (startingAngle+Angle.degrees(180))
				
				//	aligning by anchor so no X translation
				let drawX = 0.0
				//	move out to edge
				let drawY = baselineRadius * (clockwise ? -1.0 : 1.0)
				context.rotate(by: angleOfChar)
				
				context.draw(resolved, at: CGPoint(x:drawX,y:drawY), anchor: UnitPoint(vertical: kerningAlignment,horzional: .center) )

				if debugTextAlignment
				{
					let colour = GetDebugColour(characterIndex)
					let anchorX = charSize.width * -0.5
					let anchorY = charSize.height * -kerningAlignmentLetterHeight
					let charRect = CGRect(x:drawX+anchorX,y:drawY+anchorY,width: charSize.width, height:charSize.height)
					context.fill(
						Path(roundedRect: charRect, cornerSize: .zero ),
						with: .color(colour) )
				}
				
				if debugTextAlignment
				{
					let debugRadius = 6.0
					let hdr = debugRadius * 0.5
					context.fill(
						Path(ellipseIn: CGRect(x:drawX-hdr, y: drawY-hdr, width: debugRadius, height: debugRadius) ),
						with: .color(.red.opacity(0.5)) )
				}
				//	undo context matrix change
				context.rotate(by: -angleOfChar)
				
				//	move along X to right hand side to record edge
				circumferenceX += charSize.width * 0.5
			}
		}
		/*
		 //	we know the [min]size of this will be the radius specified
		 //	thus.... we should ditch radius and use geometry reader?
		 .frame(width: radius*2.0, height: radius*2.0,alignment: .center)
		 */

	}
}


//	only for preview
internal enum VerticalAlignOption : CaseIterable, Identifiable
{
	var id: Self { self }
	
	case Top,Middle,Bottom
	
	var verticalAlignment : VerticalAlignment
	{
		switch(self)
		{
			case .Top:	return VerticalAlignment.top
			case .Middle:	return VerticalAlignment.center
			case .Bottom:	return VerticalAlignment.bottom
		}
	}
}


//	@Previewable only in 14+
@available(macOS 14.0, iOS 17.0, *) 
#Preview
{
	@Previewable @State var verticalKerningAlignmentOption : VerticalAlignOption = .Middle
	@Previewable @State var showDebug = true
	@Previewable @State var startingAngleDegrees : Float = -90
	@Previewable @State var radius : CGFloat = 300
	@Previewable @State var fontSize : CGFloat = 50
	var startingAngle : Angle {	Angle.degrees(Double(startingAngleDegrees))	}
	var verticalKerningAlignment : VerticalAlignment	{	verticalKerningAlignmentOption.verticalAlignment	}
	
	CircularTextView("hello",startingAngle: startingAngle, kerningAlignment:verticalKerningAlignment,debug: showDebug)
		.frame(width:radius,height:radius)
		.background( Circle().fill(.black) )
		.font(.system(size: fontSize))
		.foregroundColor(.white)
	
	CircularTextView("anti-clockwise",startingAngle: Angle.degrees(180), kerningAlignment:verticalKerningAlignment,clockwise:false, debug: showDebug)
		.frame(width:radius,height:radius)
		.background( Circle().fill(.black) )
		.font(.system(size: fontSize))
		.foregroundColor(.white)
	
	VStack
	{
		HStack
		{
			Text("Radius: \(Int(radius))")
				.frame(width:100)
			Slider(value:$radius,in: 1...400)
		}
		
		HStack
		{
			Text("Font Size: \(Int(fontSize))")
				.frame(width:100)
			Slider(value:$fontSize,in: 1...400)
		}
		
		
		Toggle("Show Debug",isOn:$showDebug)
		
		HStack
		{
			Text("Starting angle: \(Int(startingAngleDegrees)) degrees")
				.frame(width:100)
			Slider(value:$startingAngleDegrees,in: -180...360)
		}
		
		Picker("Vertical Kerning Alignment", selection: $verticalKerningAlignmentOption) 
		{
			ForEach(VerticalAlignOption.allCases) 
			{
				Text(String("\($0)"))
			}
		}
	}
	.padding(20)
}
