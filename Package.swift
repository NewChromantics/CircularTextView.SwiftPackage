// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.


import PackageDescription



let package = Package(
	name: "CircularTextView",
	
	platforms: [
		.iOS(.v13),
		.macOS(.v12)	//	Cavnas is 12+	
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
