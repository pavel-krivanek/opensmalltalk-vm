"
I am an abstract superclass for all classes in the VM that want to maintain a source timeStamp.  I am also the holder of the InitializationOptions class variable which holds options such as which JIT or which memory manager to use when creating or generating a VM.
"
Class {
	#name : #VMClass,
	#superclass : #CCGClass,
	#category : #'VMMaker-Translation to C'
}

{ #category : #initialization }
VMClass class >> initializeMiscConstants [
	"Falsify the `what type of VM is this?' flags that are defined in the various interp.h files.
	 Subclass implementations need to include a super initializeMiscConstants"
	
	| omc |

	super initializeMiscConstants.

	VMBIGENDIAN class. "Mention this for the benefit of CCodeGenerator>>emitCConstantsOn:"
	SPURVM := STACKVM := COGVM := COGMTVM := false.

	InitializationOptions ifNil: [InitializationOptions := Dictionary new].
	omc := InitializationOptions at: #ObjectMemory ifAbsent: nil.
	(omc isNil and: [self defaultObjectMemoryClass notNil]) ifTrue:
		[omc := InitializationOptions at: #ObjectMemory put: self defaultObjectMemoryClass name].
	InitializationOptions
		at: #SqueakV3ObjectMemory	"the good ole default"
			ifAbsentPut: (omc
					ifNil: [true]
					ifNotNil: [(Smalltalk at: omc) includesBehavior: ObjectMemory]);
		at: #SpurObjectMemory		"the new contender"
			ifAbsentPut: (omc
					ifNil: [false]
					ifNotNil: [(Smalltalk at: omc) includesBehavior: SpurMemoryManager]).

	"Use ifAbsentPut: so that they will get copied back to the
	 VMMaker's options and dead code will likely be eliminated."
	PharoVM := InitializationOptions at: #PharoVM ifAbsentPut: [false].
	NewspeakVM := InitializationOptions at: #NewspeakVM ifAbsentPut: [false].
	SistaVM := InitializationOptions at: #SistaVM ifAbsentPut: [false].
	TempVectReadBarrier := InitializationOptions at: #TempVectReadBarrier ifAbsentPut: [false].
	LowcodeVM := InitializationOptions at: #LowcodeVM ifAbsentPut: [false].
	MULTIPLEBYTECODESETS := InitializationOptions at: #MULTIPLEBYTECODESETS ifAbsentPut: [false].
	"Simulation only; on by default..."
	CloneOnGC := InitializationOptions at: #CloneOnGC ifAbsentPut: [true].
	CloneOnScavenge := InitializationOptions at: #CloneOnScavenge ifAbsentPut: [true].

	"These must be set only if specified, not defaulted, because they are set on the command line or in include files."
	InitializationOptions
		at: #VMBIGENDIAN	ifPresent: [:value| VMBIGENDIAN := value];
		at: #ObjectMemory	ifPresent: [:value| SPURVM := value beginsWith: 'Spur'];
		at: #STACKVM		ifPresent: [:value| STACKVM := value];
		at: #COGVM		ifPresent: [:value| COGVM := InitializationOptions at: #COGVM];
		at: #COGMTVM		ifPresent: [:value| COGMTVM := InitializationOptions at: #COGMTVM].

	"consistency checks"
	SPURVM
		ifTrue:
			[(TempVectReadBarrier not
			  and: [{SpurMemoryManager compactorClass}, (SpurMemoryManager compactorClass ancilliaryClasses) anySatisfy:
						[:c| c == SpurSelectiveCompactor]]) ifTrue:
				[self error: 'Selective compactor requires read barrier']]
		ifFalse:
			[TempVectReadBarrier ifTrue: [self error: 'read barrier works with spur VM only...'].
			 SistaVM ifTrue: [self error: 'Sista VM works with spur VM only...']].

	"And not these; they're compile-time"
	IMMUTABILITY := InitializationOptions at: #IMMUTABILITY ifAbsent: [SPURVM] "Default as enabled for Spur VMs"
]

{ #category : #translation }
VMClass class >> shouldGenerateTypedefFor: aStructClass [
	"Hack to work-around multiple definitions.  Sometimes a type has been defined in an include."
	^aStructClass ~~ VMCallbackContext
]

{ #category : #'C library simulation' }
VMClass >> addressOf: anObject put: aBlock [
	<doNotGenerate>
	"Simulate a C pointer.  Translates into &anObject in C. Provides something
	 that evaluates aBlock with the new value in response to at:put:"
	| thing |
	thing := anObject.
	^CPluggableAccessor new
		setObject: nil;
		atBlock: [:obj :idx| thing]
		atPutBlock: [:obj :idx :val| aBlock value: (thing := val)]
]

{ #category : #'C library simulation' }
VMClass >> alloca: size [
	"Simulation of alloca(3)"
	<doNotGenerate>
	^ByteArray new: size
]

{ #category : #'C library simulation' }
VMClass >> alloca: numElements type: elementType [
	<cmacro: '(numElements, elementType) alloca((numElements)*sizeof(elementType))'>
	^CArrayAccessor on: ((1 to: numElements) collect: [:ign| elementType new])
]

{ #category : #'translation support' }
VMClass >> asAddress: address put: aBlock [
	<doNotGenerate>
	"Simulate a C pointer.  Translates into address in C. Provides something
	 that evaluates aBlock with the new value in response to at:put:"
	^CPluggableAccessor new
		setObject: nil;
		atBlock: [:obj :idx| self error: 'cannot dereference pseudo-pointers']
		atPutBlock: [:obj :idx :val| aBlock value: val]
]

{ #category : #'C library simulation' }
VMClass >> malloc: size [
	<doNotGenerate>
	^CArrayAccessor on: (ByteArray new: size)
]
