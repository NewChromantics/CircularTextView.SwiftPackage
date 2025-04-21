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
	//	gr: @State to cache - new .text creates whole new view so this doesnt need resetting
	//		this may need to change for future animations
	@State private var characterWidths: [Character:Double] = [:]
	@State private var letterHeight : CGFloat = 0.0
	
	//	read current font
	@Environment(\.font) var font
	
	var text : String
	
	var startingAngle : Angle
	
	//	align letter rotations at the top (0) bottom (1.0) or middle (0.5)
	let kerningAlignment : VerticalAlignment = .center
	var debugTextAlignment = true
	
	//	see comments on usage - this should be 1.0 but is squashed together
	var magicKerningScalar : CGFloat { 6.0 }
	
	public init(_ text: String, startingAngle: Angle = .degrees(0))
	{
		self.text = text
		self.startingAngle = startingAngle
	}
	
	func ResetCache()
	{
		characterWidths = [:]
	}
	
	func GetColour(_ index:Int) -> Color
	{
		let colours : [Color] = [.red,.orange,.yellow,.green,.cyan,.blue,.purple,.pink]
		let colour = colours[ index % colours.count]
		return colour.opacity( debugTextAlignment ? 0.7 : 0.0 )
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
			for textElement in texts
			{
				/*
				 let textElement = Text(String(char.element))
				 .foregroundColor(.yellow)
				 .font(font)
				 */
				let resolved = context.resolve(textElement)
				var charSize = resolved.measure(in: CGSize(width: 900, height: 900))
				
				//	gr: magic kerning number - this should be 1.0
				//		in swiftui 0.0 is default
				charSize.width *= magicKerningScalar
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
		.onChange(of: self.text)
		{
			ResetCache()
		}
	}
	
	
}



#Preview
{
	CircularTextView("hello")
		.frame(width:100)
		.background(.blue)
		.fontWeight(.bold)
		.font(.system(size: 20))
		.foregroundColor(.red)
}
