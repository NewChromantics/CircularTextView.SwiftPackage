// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.


import PackageDescription



let package = Package(
	name: "CircularTextView",
	
	platforms: [
		.iOS(.v15),		//	Canvas 15+
		.macOS(.v12)	//	Canvas is 12+	
	],
	
	products: [
		.library(
			name: "CircularTextView",
			targets: [
				"CircularTextView"
			]),
	],
	
	dependencies: [
	],
	
	targets: [

		.target(
			name: "CircularTextView"
		)
	]
)
