Extension { #name : #CCGClass }

{ #category : #'*VMMaker' }
CCGClass >> doOrDefer: aBlock [
	<doNotGenerate>
	"Either evaluate aBlock immediately if in the uiProcess or defer aBlock as a UI message"
	Processor activeProcess == self uiProcess
		ifTrue: [aBlock value]
		ifFalse: [WorldState addDeferredUIMessage: aBlock]
]

{ #category : #'*VMMaker' }
CCGClass class >> openCogMultiWindowBrowser [
	"Answer a new multi-window browser on the ObjectMemory classes, the Cog Interpreter classes, and the main JIT classes"
	| b |
	b := Browser open.
	#(	ObjectMemory NewObjectMemory NewCoObjectMemory
		InterpreterPrimitives StackInterpreter StackInterpreterPrimitives CoInterpreter CoInterpreterPrimitives CoInterpreterMT
		Cogit SimpleStackBasedCogit StackToRegisterMappingCogit
		VMStructType VMMaker CCodeGenerator TMethod)
		do: [:className|
			(Smalltalk classNamed: className) ifNotNil:
				[:class| b selectCategoryForClass: class; selectClass: class]]
		separatedBy:
			[b multiWindowState addNewWindow].
	b multiWindowState selectWindowIndex: 1
]

{ #category : #'*VMMaker' }
CCGClass class >> openCogSpurMultiWindowBrowser [
	"Answer a new multi-window browser on the ObjectMemory classes, the Cog Interpreter classes, and the main JIT classes"
	| b |
	b := Browser open.
	#(	SpurMemoryManager Spur32BitMemoryManager Spur32BitCoMemoryManager
		 Spur64BitMemoryManager Spur64BitCoMemoryManager SpurGenerationScavenger
		InterpreterPrimitives StackInterpreter StackInterpreterPrimitives CoInterpreter CoInterpreterPrimitives CoInterpreterMT
		Cogit SimpleStackBasedCogit StackToRegisterMappingCogit
		CogObjectRepresentation CogObjectRepresentationForSpur
		CogObjectRepresentationFor32BitSpur CogObjectRepresentationFor64BitSpur
		VMStructType VMMaker CCodeGenerator TMethod)
		do: [:className|
			(Smalltalk classNamed: className) ifNotNil:
				[:class| b selectCategoryForClass: class; selectClass: class]]
		separatedBy:
			[b multiWindowState addNewWindow].
	b multiWindowState selectWindowIndex: 1
]

{ #category : #'*VMMaker' }
CCGClass class >> openCogTestsMultiWindowBrowser [
	"Answer a new multi-window browser on the test classes in VMMaker"
	"self openCogTestsMultiWindowBrowser"
	| testClasses b |
	testClasses := (PackageInfo named: 'VMMaker') classes select: [:c| c inheritsFrom: TestCase].
	testClasses removeAll: AbstractInstructionTests allSubclasses.
	testClasses removeAll: (testClasses select: [:c| '*Plugin*' match: c name]).
	b := Browser open.
	testClasses do:
		[:class| b selectCategoryForClass: class; selectClass: class]
		separatedBy:
			[b multiWindowState addNewWindow].
	b multiWindowState selectWindowIndex: 1
]

{ #category : #'*VMMaker' }
CCGClass class >> openCogitMultiWindowBrowser [
	"Answer a new multi-window browser on the ObjectMemory classes, the Cog Interpreter classes, and the main JIT classes"
	"self openCogitMultiWindowBrowser"
	| b |
	b := Browser open.
	Cogit withAllSubclasses,
	CogObjectRepresentation withAllSubclasses,
	{CogMethodZone. CogRTLOpcodes },
	(CogAbstractInstruction withAllSubclasses reject: [:c| c name endsWith: 'Tests']),
	CogBytecodeFixup withAllSubclasses,
	CogSimStackEntry withAllSubclasses,
	{VMStructType. VMMaker. CCodeGenerator. TMethod}
		do: [:class|
			b selectCategoryForClass: class; selectClass: class]
		separatedBy:
			[b multiWindowState addNewWindow].
	b multiWindowState selectWindowIndex: 1
]

{ #category : #'*VMMaker' }
CCGClass class >> openObjectMemoriesInterpretersBrowser [
	"Answer a new multi-window browser on the ObjectMemory classes and the Cog Interpreter classes"
	| b |
	b := Browser open.
	#(	ObjectMemory NewObjectMemory NewCoObjectMemory
		InterpreterPrimitives StackInterpreter StackInterpreterPrimitives
		CoInterpreter CoInterpreterPrimitives CoInterpreterMT)
		do: [:className|
			(Smalltalk classNamed: className) ifNotNil:
				[:class| b selectCategoryForClass: class; selectClass: class]]
		separatedBy:
			[b multiWindowState addNewWindow].
	b multiWindowState selectWindowIndex: 1
]

{ #category : #'*VMMaker' }
CCGClass class >> openSpurMultiWindowBrowser [
	"Answer a new multi-window browser on the Spur classes, the Cog StackInterpreter classes, and the support classes"
	| b |
	b := Browser open.
	#(	SpurMemoryManager Spur32BitMemoryManager Spur64BitMemoryManager
		SpurGenerationScavenger SpurSegmentManager
		Spur32BitMMLESimulator SpurGenerationScavengerSimulator
		InterpreterPrimitives StackInterpreter StackInterpreterPrimitives
		VMStructType VMMaker CCodeGenerator TMethod)
		do: [:className|
			(Smalltalk classNamed: className) ifNotNil:
				[:class| b selectCategoryForClass: class; selectClass: class]]
		separatedBy:
			[b multiWindowState addNewWindow].
	b multiWindowState selectWindowIndex: 1
]
