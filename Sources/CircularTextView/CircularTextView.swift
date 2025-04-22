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
	
	//	align letter rotations at the top, bottom or middle
	let kerningAlignment : VerticalAlignment
	var debugTextAlignment = false
	
	//	see comments on usage - this should be 1.0 but is squashed together
	//	6.0 is about right for all cases... but I feel must be related to font size
	var magicKerningScalar : CGFloat
	{
		return 6.2
	}	
	
	public init(_ text:String,startingAngle:Angle = .degrees(0), kerningAlignment:VerticalAlignment = .center,debug:Bool=false)
	{
		self.text = text
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
			//let circumference = times2pi( baselineRadius )
			
			let times2pi : (Double) -> Double = { $0 * 2 * .pi }
			
			//	make all operations start at the center
			context.translateBy(x: canvasSize.width/2.0, y: canvasSize.height/2.0)
			
			//for char in Array(text.enumerated())
			var index = 0
			for textElement in texts
			{
				index += 1
				/*
				 let textElement = Text(String(char.element))
				 .foregroundColor(.yellow)
				 .font(font)
				 */
				let resolved = context.resolve(textElement)
				let measuredCharSize = resolved.measure(in: CGSize(width: 900, height: 900))
				var charSize = measuredCharSize
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

				//	gr: magic kerning number - this should be 1.0
				//		in swiftui 0.0 is default
				let kerningScalar = magicKerningScalar//* (letterHeight*kerningAlignmentLetterHeight)
				charSize.width *= kerningScalar
				//print("Char \(char.element) height = \(charSize.height)")
				
				let baselineRadius = viewRadius - (letterHeight*kerningAlignmentLetterHeight)
				let circumference = times2pi( baselineRadius )
				
				//	move x pos across so we have the center
				//	but not if we're the first
				//if char.offset > 0
				if circumferenceX > 0.0
				{
					circumferenceX += charSize.width * 0.5
				}
				
				//	pos along circumference to angle
				var angleOfChar = Angle.radians( circumferenceX / circumference )
				
				//	expecting this to be -startingAngle, but as Y is flipped, we add
				angleOfChar += startingAngle
				
				//	aligning by anchor so no X translation
				let drawX = 0.0
				//	move out to edge
				let drawY = baselineRadius * -1.0
				context.rotate(by: angleOfChar)
				
				context.draw(resolved, at: CGPoint(x:drawX,y:drawY), anchor: UnitPoint(vertical: kerningAlignment,horzional: .center) )

				if debugTextAlignment
				{
					let colour = GetDebugColour(index)
					let anchorX = measuredCharSize.width * -0.5
					let anchorY = measuredCharSize.height * -kerningAlignmentLetterHeight
					let charRect = CGRect(x:drawX+anchorX,y:drawY+anchorY,width: measuredCharSize.width, height:measuredCharSize.height)
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
@available(macOS 14.0, *) 
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
