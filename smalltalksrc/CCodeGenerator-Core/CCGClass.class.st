Class {
	#name : #CCGClass,
	#superclass : #Object,
	#classVars : [
		'DefaultBase',
		'ExpensiveAsserts',
		'InitializationOptions'
	],
	#pools : [
		'VMBasicConstants',
		'VMObjectIndices'
	],
	#classInstVars : [
		'timeStamp'
	],
	#category : #'CCodeGenerator-Core'
}

{ #category : #translation }
CCGClass class >> ancilliaryClasses [
	"Answer any extra classes to be included in the translation."
	^{}
]

{ #category : #translation }
CCGClass class >> apiExportHeaderName [
	"VM classesd that want to generate an api export header override this."
	^nil
]

{ #category : #'adding/removing methods' }
CCGClass class >> basicRemoveSelector: aSelector [
	"Override to update the timeStamp"
	^(super basicRemoveSelector: aSelector) ifNotNil:
		[:oldMethod| self touch. oldMethod]
]

{ #category : #'accessing class hierarchy' }
CCGClass class >> cogitClass [
	"Answer the cogitClass in effect.  Ensure that StackInterpreter has a nil cogitClass."
	(self isInterpreterClass and: [self hasCogit not]) ifTrue:
		[^nil].
	^Smalltalk classNamed: (InitializationOptions
								at: #Cogit
								ifAbsent: [#StackToRegisterMappingCogit])
]

{ #category : #'accessing class hierarchy' }
CCGClass class >> coreInterpreterClass [
	"While the interpreterClass/vmClass for translation may be
	 a subclass that holds a few primitives we want the actual
	 interpreter name at the head of the generated file."
	^((name endsWith: 'Primitives')
	   and: [name beginsWith: superclass name])
		ifTrue: [superclass]
		ifFalse: [self]
]

{ #category : #translation }
CCGClass class >> declareC: arrayOfVariableNames as: aCType in: aCCodeGenerator [
	"Declare the variables in arrayOfVariableNames with the given type."

	arrayOfVariableNames
		do: [:varName | aCCodeGenerator var: varName type: aCType]
]

{ #category : #translation }
CCGClass class >> declareCAsOop: arrayOfVariableNames in: aCCodeGenerator [
	"Declare the variables in arrayOfVariableNames with type representing position in object memory."

	arrayOfVariableNames do:
		[:varName| aCCodeGenerator var: varName type: #usqInt]
]

{ #category : #translation }
CCGClass class >> declareCAsUSqLong: arrayOfVariableNames in: aCCodeGenerator [
	"Declare the variables in arrayOfVariableNames with type representing position in object memory."

	arrayOfVariableNames do:
		[:varName| aCCodeGenerator var: varName type: #usqLong]
]

{ #category : #translation }
CCGClass class >> declareCVarsIn: aCCodeGenerator [ 
	"Declare any additional variables and/or add type declarations for existing variables."
	aCCodeGenerator
		var: #expensiveAsserts
		declareC: 'char expensiveAsserts = 0'
]

{ #category : #translation }
CCGClass class >> declareInterpreterVersionIn: aCCodeGenerator defaultName: defaultName [
	NewspeakVM ifTrue:
		["Newspeak as of mid 2011 derives SystemScope systemName from the interpreterVersion
		  (via system attribute 1004) by copying up to but not including the last space, provided the
		  string ends with a digit.  So spaces must be eliminated from the Monitcello version string,
		  and we can't surround it with square brackets."
		(aCCodeGenerator shortMonticelloDescriptionForClass: self) last isDigit ifFalse:
			[self error: 'Newspeak expects interpreterVersion ends with a digit'].
		aCCodeGenerator
			var: #interpreterVersion
			declareC: 'const char *interpreterVersion = "Newspeak Virtual Machine ',
							((aCCodeGenerator shortMonticelloDescriptionForClass: self) copyReplaceAll: ' ' with: '_'),
							'"'.
		^self].
	
	aCCodeGenerator
		var: #interpreterVersion
		declareC: 'const char *interpreterVersion = "Croquet Closure ', defaultName, ' VM [',
					(aCCodeGenerator shortMonticelloDescriptionForClass: self),']"'.
]

{ #category : #debugger }
CCGClass class >> defaultIntegerBaseInDebugger [
	"DefaultBase := 16."
	"DefaultBase := 10."
	DefaultBase isNil ifTrue: [DefaultBase := 16].
	^DefaultBase
]

{ #category : #'accessing class hierarchy' }
CCGClass class >> defaultObjectMemoryClass [
	"Default for all-in-one VMs where the interpreter inherits from the object memory."
	^nil
]

{ #category : #'as yet unclassified' }
CCGClass class >> exportHeaders [

'sq.h' asFileReference writeStreamDo: [ :f |
	f nextPutAll: 
'#ifndef __sq_h
#define __sq_h

#include <stdlib.h>
#include <math.h>
 
#define SQ_VI_BYTES_PER_WORD 4
#define SIZEOF_VOID_P 4

#if (SQ_VI_BYTES_PER_WORD == 4)
# define SQ_IMAGE32 1
#else
# define SQ_IMAGE64 1
#endif

#if (SIZEOF_VOID_P == 4)
# define SQ_HOST32 1
#elif (SIZEOF_VOID_P == 8)
# define SQ_HOST64 1
#else
# error host is neither 32- nor 64-bit?
#endif

#if defined(SQ_IMAGE32)
typedef int   sqInt;
typedef unsigned int  usqInt;
#elif defined(SQ_HOST64)
typedef long    sqInt;
typedef unsigned long usqInt;
#else
# if (SIZEOF_LONG_LONG != 8)
#   error long long integers are not 64-bits wide?
# endif 
typedef long long   sqInt;
typedef unsigned long long  usqInt;
#endif

#if defined(SQ_IMAGE32)
  typedef int		sqInt;
  typedef unsigned int	usqInt;
# define SQABS abs
#elif defined(SQ_HOST64)
  typedef long		sqInt;
  typedef unsigned long	usqInt;
# define SQABS labs
#elif (SIZEOF_LONG_LONG != 8)
#   error long long integers are not 64-bits wide?
#else
  typedef long long		sqInt;
  typedef unsigned long long	usqInt;
# define SQABS llabs
#endif

#if defined(__BIG_ENDIAN__)
# define VMBIGENDIAN 1
#else
# define VMBIGENDIAN 0
#endif

# define __stringify(foo) #foo
# define __stringifyNum(n) __stringify(n)

extern void warning(char *);
extern void warningat(char *,int);

# define assert(expr)  ((expr)||(warning(#expr " " __stringifyNum(__LINE__)),0))
# define asserta(expr) ((expr)||(warning(#expr " " __stringifyNum(__LINE__)),0))
/*# define assertf(msg)  (warning(#msg " " __stringifyNum(__LINE__)),0)*/
# define assertl(expr,line)  ((expr)||(warningat(#expr,line),0))
# define assertal(expr,line) ((expr)||(warningat(#expr,line),0))
# define assertfl(msg,line)  (warningat(#msg,line),0)

# define eassert(expr)  (!expensiveAsserts||(expr) \
						 ||(warning(#expr " " __stringifyNum(__LINE__)),0))


#define EXPORT(returnType) returnType

#define null 0

#define SQ_SWAP_4_BYTES(x) \
	(((unsigned int)(x) << 24) | \
	(((unsigned int)(x) <<  8) & 0xff0000U) | \
	(((unsigned int)(x) >>  8) & 0xff00U) | \
	( (unsigned int)(x) >> 24))
#define SQ_SWAP_8_BYTES(x) \
	(((unsigned long long)(x) << 56) | \
	(((unsigned long long)(x) << 40) & 0xff000000000000ULL) | \
	(((unsigned long long)(x) << 24) & 0xff0000000000ULL) | \
	(((unsigned long long)(x) << 8)  & 0xff00000000ULL) | \
	(((unsigned long long)(x) >> 8)  & 0xff000000ULL) | \
	(((unsigned long long)(x) >> 24) & 0xff0000ULL) | \
	(((unsigned long long)(x) >> 40) & 0xff00ULL) | \
	( (unsigned long long)(x) >> 56))
	
/* Since Large Integers are Bytes Oops allways stored as little endian,
   the following macros are handy to retrieve 4 or 8 byte limbs */
#if VMBIGENDIAN
#  define SQ_SWAP_4_BYTES_IF_BIGENDIAN(x) SQ_SWAP_4_BYTES(x)
#  define SQ_SWAP_8_BYTES_IF_BIGENDIAN(x) SQ_SWAP_8_BYTES(x)
#else
#  define SQ_SWAP_4_BYTES_IF_BIGENDIAN(x) (x)
#  define SQ_SWAP_8_BYTES_IF_BIGENDIAN(x) (x)
#endif

/* sqLong is a signed integer with at least 64bits on both 32 and 64 bits images
   usqLong is the unsigned flavour
   SQLABS is a macro for taking absolute value of a sqLong */
#if !defined(sqLong)
#  if SIZEOF_LONG == 8
#     define sqLong long
#     define usqLong unsigned long
#     define SQLABS labs
#  elif _MSC_VER
#     define sqLong __int64
#     define usqLong unsigned __int64
#     define SQLABS llabs
#  else
#     define sqLong long long
#     define usqLong unsigned long long
#     define SQLABS llabs
#  endif
#endif /* !defined(sqLong) */

#endif /* __sq_h */
' ]
]

{ #category : #translation }
CCGClass class >> getVMMaker [
	^Notification new tag: #getVMMaker; signal
]

{ #category : #'accessing class hierarchy' }
CCGClass class >> hasCogit [
	^false
]

{ #category : #translation }
CCGClass class >> implicitReturnTypeFor: aSelector [
	"Answer the return type for methods that don't have an explicit return."
	^#sqInt
]

{ #category : #initialization }
CCGClass class >> initializationOptions [
	^InitializationOptions
]

{ #category : #initialization }
CCGClass class >> initialize [
	InitializationOptions ifNil: [InitializationOptions := Dictionary new].
	ExpensiveAsserts := false.
	(Smalltalk classNamed: #Utilities) ifNotNil:
		[:utilitiesClass|
		 (utilitiesClass classPool at: #CommonRequestStrings ifAbsent: []) ifNotNil:
			[:commonRequestStringHolder|
			(commonRequestStringHolder contents asString includesSubstring: 'VMClass open') ifFalse:
				[Utilities appendToCommonRequests: '-\VMMaker generateConfiguration\VMMaker generateAllConfigurationsUnderVersionControl\VMMaker generateAllSpurConfigurations\VMClass openCogMultiWindowBrowser\VMClass openObjectMemoriesInterpretersBrowser\VMClass openSpurMultiWindowBrowser\VMClass openCogSpurMultiWindowBrowser\VMClass openCogitMultiWindowBrowser' withCRs]]]
]

{ #category : #initialization }
CCGClass class >> initializeForPlugins: optionsDictionaryOrArray [
	"Do a default initialization, suitable for generating plugin sources."
	StackInterpreterSimulator
		initializeWithOptions: optionsDictionaryOrArray
		objectMemoryClass: ObjectMemory
]

{ #category : #initialization }
CCGClass class >> initializeMiscConstants [

]

{ #category : #initialization }
CCGClass class >> initializePrimitiveErrorCodes [
	"Define the VM's primitive error codes.  N.B. these are
	 replicated in platforms/Cross/vm/sqVirtualMachine.h."
	"VMClass initializePrimitiveErrorCodes"
	| pet |
	PrimErrTableIndex := 51. "Zero-relative"
	"See SmalltalkImage>>recreateSpecialObjectsArray for the table definition.
	 If the table exists and is large enough the corresponding entry is returned as
	 the primitive error, otherwise the error is answered numerically."
	pet := Smalltalk specialObjectsArray at: PrimErrTableIndex + 1 ifAbsent: [#()].
	pet isArray ifFalse: [pet := #()].
	PrimNoErr := 0. "for helper methods that need to answer success or an error code."
	PrimErrGenericFailure		:= pet indexOf: nil ifAbsent: 1.
	PrimErrBadReceiver			:= pet indexOf: #'bad receiver' ifAbsent: 2.
	PrimErrBadArgument		:= pet indexOf: #'bad argument' ifAbsent: 3.
	PrimErrBadIndex			:= pet indexOf: #'bad index' ifAbsent: 4.
	PrimErrBadNumArgs		:= pet indexOf: #'bad number of arguments' ifAbsent: 5.
	PrimErrInappropriate		:= pet indexOf: #'inappropriate operation' ifAbsent: 6.
	PrimErrUnsupported		:= pet indexOf: #'unsupported operation' ifAbsent: 7.
	PrimErrNoModification		:= pet indexOf: #'no modification' ifAbsent: 8.
	PrimErrNoMemory			:= pet indexOf: #'insufficient object memory' ifAbsent: 9.
	PrimErrNoCMemory			:= pet indexOf: #'insufficient C memory' ifAbsent: 10.
	PrimErrNotFound			:= pet indexOf: #'not found' ifAbsent: 11.
	PrimErrBadMethod			:= pet indexOf: #'bad method' ifAbsent: 12.
	PrimErrNamedInternal		:= pet indexOf: #'internal error in named primitive machinery' ifAbsent: 13.
	PrimErrObjectMayMove		:= pet indexOf: #'object may move' ifAbsent: 14.
	PrimErrLimitExceeded		:= pet indexOf: #'resource limit exceeded' ifAbsent: 15.
	PrimErrObjectIsPinned		:= pet indexOf: #'object is pinned' ifAbsent: 16.
	PrimErrWritePastObject		:= pet indexOf: #'primitive write beyond end of object' ifAbsent: 17.
	PrimErrObjectMoved		:= pet indexOf: #'object moved' ifAbsent: 18.
	PrimErrObjectNotPinned	:= pet indexOf: #'object not pinned' ifAbsent: 19.
	PrimErrCallbackError		:= pet indexOf: #'error in callback' ifAbsent: 20.
	PrimErrOSError				:= pet indexOf: #'operating system error' ifAbsent: 21.
	PrimErrFFIException		:= pet indexOf: #'ffi call exception' ifAbsent: 22.
	PrimErrNeedCompaction	:= pet indexOf: #'heap compaction needed' ifAbsent: 23. "N.B. This is currently an internal error in Spur image segment saving."
	PrimErrOperationFailed		:= pet indexOf: #'operation failed' ifAbsent: 24
]

{ #category : #initialization }
CCGClass class >> initializeWithOptions: optionsDictionaryOrArray [
	"Initialize the receiver, typically initializing class variables. Initialize any class variables
	 whose names occur in optionsDictionary with the corresponding values there-in."
	InitializationOptions := optionsDictionaryOrArray isArray
								ifTrue: [Dictionary newFromPairs: optionsDictionaryOrArray]
								ifFalse: [optionsDictionaryOrArray].

	ExpensiveAsserts := InitializationOptions at: #ExpensiveAsserts ifAbsent: [false]
]

{ #category : #'accessing class hierarchy' }
CCGClass class >> interpreterClass [
	^self isInterpreterClass ifTrue: [self]
]

{ #category : #accessing }
CCGClass class >> interpreterVersion [ 
	^ self subclassResponsibility
]

{ #category : #translation }
CCGClass class >> isAcceptableAncilliaryClass: aClass [
	^true
]

{ #category : #translation }
CCGClass class >> isAccessor: aSelector [
	"Answer if aSelector is simply an accessor method for one of our fields.
	 Answer false by default.  VMStructType classes redefine this appropriately."
	^false
]

{ #category : #translation }
CCGClass class >> isCogitClass [
	"The various Cogit classes override this."
	^false
]

{ #category : #translation }
CCGClass class >> isInterpreterClass [
	"The various Interpreter classes override this."
	^false
]

{ #category : #translation }
CCGClass class >> isNonArgumentImplicitReceiverVariableName: aString [
	^false
]

{ #category : #translation }
CCGClass class >> isPluginClass [
	"InterpreterPlugin class override this."
	^false
]

{ #category : #translation }
CCGClass class >> isStructClass [
	"The various VMStructType classes override this."
	^false
]

{ #category : #accessing }
CCGClass class >> memoryManagerVersion [ 
	^ self subclassResponsibility
]

{ #category : #translation }
CCGClass class >> monticelloDescription [
	"Answer the Monticello version of the packlage containing the receiver.
	 This is a hook to allow subclasses to expand upon the default monticello description."
	^CCodeGenerator monticelloDescriptionFor: self
]

{ #category : #translation }
CCGClass class >> mustBeGlobal: var [
	"Answer if a variable must be global and exported.  Used for inst vars that are accessed from VM support code."

	^var = #expensiveAsserts
]

{ #category : #translation }
CCGClass class >> noteCompilationOf: aSelector meta: isMeta [
	"note the recompiliation by resetting the timeStamp "
	timeStamp := Time totalSeconds.
	^super noteCompilationOf: aSelector meta: isMeta
]

{ #category : #'accessing class hierarchy' }
CCGClass class >> objectMemoryClass [
	InitializationOptions ifNil:
		[^self defaultObjectMemoryClass].
	^Smalltalk at: (InitializationOptions
					at: #ObjectMemory
					ifAbsent: [^self defaultObjectMemoryClass])
]

{ #category : #'accessing class hierarchy' }
CCGClass class >> objectRepresentationClass [
	^self objectMemoryClass objectRepresentationClass
]

{ #category : #translation }
CCGClass class >> prepareToBeAddedToCodeGenerator: aCCodeGenerator [ 
	"Hook for translation.  e.g. allows a subclass to override its
	 superclass's methods by deleting them before it adds its own."
]

{ #category : #translation }
CCGClass class >> requiredMethodNames: options [
	"Answer a list of method names that should be retained for export or other
	 support reasons.  These are typically entry-points that unless explicitly noted
	 will be deleted by the code generator since it will assume these are not used."
	^#()
]

{ #category : #translation }
CCGClass class >> shouldGenerateDeadCode [
	"Answer if the code generator should generate dead code, e.g. in false ifTrue: [dead] ifFalse: [live].
	 This *may* be useful in debugging (see CCodeGenerator>>nilOrBooleanConstantReceiverOf: et al).
	 But by default we answer false."

	^false
]

{ #category : #translation }
CCGClass class >> shouldGenerateTypedefFor: aStructClass [
	^ true
]

{ #category : #translation }
CCGClass class >> shouldIncludeMethodForSelector: selector [
	"Answer whether a primitive method should be translated.  Emit a warning to the transcript if the method doesn't exist."
	^(self whichClassIncludesSelector: selector)
		ifNotNil:
			[:c|
			 (c >> selector pragmaAt: #option:)
				ifNotNil:
					[:pragma|
					(VMBasicConstants defineAtCompileTime: pragma arguments first)
					 or: [InitializationOptions
							at: pragma arguments first
							ifAbsent: [(self bindingOf: pragma arguments first)
										ifNil: [false]
										ifNotNil: [:binding| binding value ~~ #undefined]]]]
				ifNil: [true]]
		ifNil:
			[Transcript nextPutAll: 'Cannot find implementation of '; nextPutAll: selector; nextPutAll: ' in hierarchy of '; print: self; cr; flush.
			 false]
]

{ #category : #simulation }
CCGClass class >> simulatorClass [
	"For running from Smalltalk - answer a class that can be used to simulate the receiver."

	^self
]

{ #category : #translation }
CCGClass class >> specialValueForConstant: constantName default: defaultValue [
	^nil
]

{ #category : #translation }
CCGClass class >> staticallyResolvePolymorphicSelector: aSelectorSymbol [
	^((self name select: [:ea| ea isUppercase]), '_', aSelectorSymbol) asSymbol
]

{ #category : #translation }
CCGClass class >> timeStamp [
	^timeStamp ifNil:[0]
]

{ #category : #translation }
CCGClass class >> touch [
	"Reset the timeStamp"
	"Smalltalk allClasses select:
		[:c| (c category includesSubString: 'VMMaker-JIT') ifTrue: [c touch]]"
	"InterpreterPlugin withAllSubclassesDo:[:pl| pl touch]"
	timeStamp := Time totalSeconds
]

{ #category : #translation }
CCGClass class >> translationClass [
	"Return the class to use as the interpreterCLass when translating.  For the all-in-one
	 VMs that inherit from ObjectMemory this is the receiver.  But for the separate VMs
	 where most primitives are in a subclass it will be the subclass with the primitives."
	^self
]

{ #category : #translation }
CCGClass class >> typeForSelf [
	"Answer the type to give self if appropriate, or nil if not."
	^nil
]

{ #category : #translation }
CCGClass class >> writeVMHeaderTo: aStream bytesPerWord: bytesPerWord generator: aCCodeGenerator [
	"Generate the contents of interp.h on aStream.  Specific Interpreter subclasses
	 override to add more stuff."
	aCCodeGenerator
		putDefineOf: 'VM_PROXY_MAJOR' as: self vmProxyMajorVersion on: aStream;
		putDefineOf: 'VM_PROXY_MINOR' as: self vmProxyMinorVersion on: aStream.
	aStream cr.
	aCCodeGenerator
		putDefineOf: 'SQ_VI_BYTES_PER_WORD' as: bytesPerWord on: aStream.
	aStream cr.

	"The most basic constants must be defined here, not in e.g. the plugin sources, to allow those
	 other sources to be shared between different builds (Spur vs SqueakV3, 32-bit vs 64-bit, etc)"
	VMBasicConstants mostBasicConstantNames asSet sorted do:
		[:constName|
		(VMBasicConstants classPool at: constName ifAbsent: []) ifNotNil:
			[:const| aCCodeGenerator putDefineOf: constName as: const on: aStream]].
	aStream cr.

	((VMBasicConstants classPool associations select: [:a| a key beginsWith: 'PrimErr'])
		sorted: [:a1 :a2| a1 value <= a2 value])
		do: [:a| aCCodeGenerator putDefineOf: a key as: a value on: aStream].
	aStream cr.

	aCCodeGenerator
		putDefineOf: 'MinSmallInteger' as: self objectMemoryClass minSmallInteger on: aStream;
		putDefineOf: 'MaxSmallInteger' as: self objectMemoryClass maxSmallInteger on: aStream;
		putDefineOf: 'NumSmallIntegerTagBits' as: self objectMemoryClass numSmallIntegerTagBits on: aStream.
	aStream cr
]

{ #category : #'translation support' }
CCGClass >> addressOf: anObject [
	<doNotGenerate>
	"Translates into &anObject in C."
	^anObject
]

{ #category : #'translation support' }
CCGClass >> addressOf: anObject put: aBlock [
	<doNotGenerate>
	self shouldBeImplemented 
]

{ #category : #'C library simulation' }
CCGClass >> alloca: size [
	"Simulation of alloca(3)"
	<doNotGenerate>
	self shouldBeImplemented 
]

{ #category : #'C library extensions' }
CCGClass >> alloca: numElements type: elementType [
	<cmacro: '(numElements, elementType) alloca((numElements)*sizeof(elementType))'>
	self shouldBeImplemented 
]

{ #category : #'translation support' }
CCGClass >> asAddress: address put: aBlock [
	<doNotGenerate>
	self shouldBeImplemented
]

{ #category : #'C library extensions' }
CCGClass >> asByteArray: aStringOrStringIndex [
	"aStringOrStringIndex is either a string or an address in the heap.
	 Create a ByteArray of the requested length form the bytes in the
	 heap starting at stringIndex."
	<doNotGenerate>
	| sz |
	aStringOrStringIndex isString ifTrue:
		[^aStringOrStringIndex asByteArray].
	sz := self strlen: aStringOrStringIndex.
	^self strncpy: (ByteArray new: sz) _: aStringOrStringIndex _: sz
]

{ #category : #'C library extensions' }
CCGClass >> asByteArray: baIndex size: baSize [
	"baIndex is an address in the heap.  Create a ByteArray of the requested length
	form the bytes in the heap starting at baIndex."
	<doNotGenerate>
	^self strncpy: (ByteArray new: baSize) _: baIndex _: baSize
]

{ #category : #'C library extensions' }
CCGClass >> asString: aStringOrStringIndex [
	"aStringOrStringIndex is either a string or an address in the heap.
	 Create a String of the requested length form the bytes in the
	 heap starting at stringIndex."
	<doNotGenerate>
	| sz |
	aStringOrStringIndex isString ifTrue:
		[^aStringOrStringIndex].
	sz := self strlen: aStringOrStringIndex.
	^self strncpy: (ByteString new: sz) _: aStringOrStringIndex _: sz
]

{ #category : #'C library extensions' }
CCGClass >> asString: stringIndex size: stringSize [
	"stringIndex is an address in the heap.  Create a String of the requested length
	form the bytes in the heap starting at stringIndex."
	<doNotGenerate>
	^self strncpy: (ByteString new: stringSize) _: stringIndex _: stringSize
]

{ #category : #'debug support' }
CCGClass >> assert: aBooleanExpression l: linenum [
	<doNotGenerate>
	^self assert: aBooleanExpression
]

{ #category : #'debug support' }
CCGClass >> asserta: aBooleanExpression [
	<doNotGenerate>
	| result |
	(result := aBooleanExpression value) ifFalse:
		[AssertionFailure signal: 'Assertion failed'].
	^result
]

{ #category : #'debug support' }
CCGClass >> asserta: aBooleanExpression l: linenum [
	<doNotGenerate>
	^self asserta: aBooleanExpression
]

{ #category : #'translation support' }
CCGClass >> cCode: codeString [
	"Support for Smalltalk-to-C translation.
	 For translation only; noop when running in Smalltalk.
	 The argument is output literally when generating C code."
	<doNotGenerate>
]

{ #category : #'translation support' }
CCGClass >> cCode: codeStringOrBlock inSmalltalk: aBlock [
	"Support for Smalltalk-to-C translation. The first argument is output when generating C code.
	  But if this code is being simulated in Smalltalk, answer the result of evaluating the given block.
	  If the first argument is a string it is output literally, and if it is a block it is translated.
	  N.B.  If the first argument is a block then replacement happens at TMethod creation time so the use
	  of cCode:inSmalltalk: with a block first argument does not prevent inlining and is hence preferred."
	<doNotGenerate>
	^aBlock value
]

{ #category : #'memory access' }
CCGClass >> cCoerce: value to: cTypeString [
	"Type coercion. For translation a cast will be emmitted. When running in Smalltalk
	  answer a suitable wrapper for correct indexing."
	<doNotGenerate>
	^value
		ifNil: [value]
		ifNotNil: [value coerceTo: cTypeString sim: self]
]

{ #category : #'translation support' }
CCGClass >> cPreprocessorDirective: codeString [
	"For translation only; noop when running in Smalltalk."
	<doNotGenerate>
]

{ #category : #'translation support' }
CCGClass >> cppIf: conditionBlockOrValue ifTrue: trueExpressionOrBlock [
	"When translated, produces #if (condition) #else #endif CPP directives.
	 Example usage:

		self cppIf: IMMUTABILITY
			ifTrue: [(self internalIsImmutable: obj) ifTrue:
						[^self primitiveFailFor: PrimErrNoModification]]"
	<doNotGenerate>
	^self cppIf: conditionBlockOrValue ifTrue: trueExpressionOrBlock ifFalse: nil
]

{ #category : #'translation support' }
CCGClass >> cppIf: conditionBlockOrSymbolValue ifTrue: trueExpressionOrBlock ifFalse: falseExpressionOrBlockOrNil [
	"When translated, produces #if (condition) #else #endif CPP directives.
	 Example usage:

		self cppIf: [BytesPerWord = 8]
			ifTrue: [self doSomethingFor64Bit]
			ifFalse: [self doSomethingFor32Bit]
		self cppIf: BytesPerWord = 8
			ifTrue: [self doSomethingFor64Bit]
			ifFalse: [self doSomethingFor32Bit]
		self cppIf: #A_GLOBAL
			ifTrue: [self doSomethingFor64Bit]
			ifFalse: [self doSomethingFor32Bit]"
	<doNotGenerate>
	^(conditionBlockOrSymbolValue value
		ifNil: [false]
		ifNotNil: [:value|
			value isInteger
				ifTrue: [value ~= 0]
				ifFalse:
					[value isSymbol
						ifTrue: [(self class bindingOf: value)
									ifNil: [false]
									ifNotNil: [:binding| binding value]]
						ifFalse: [value]]])
		ifTrue: trueExpressionOrBlock
		ifFalse: falseExpressionOrBlockOrNil
]

{ #category : #'simulation support' }
CCGClass >> deny: aBooleanOrBlock [
	<doNotGenerate>
	aBooleanOrBlock value ifTrue: [AssertionFailure signal: 'Assertion failed']
]

{ #category : #'debug support' }
CCGClass >> eassert: aBooleanExpressionOrBlock [
	"This is for expensive asserts that we're only interested in checking in extremis.
	 For example now that Spur objStacks are debugged there's no benefit to
	 evaluating isValidObjStack: throughout the mark loop because its damn slow."
	<doNotGenerate>
	ExpensiveAsserts ifTrue:
		[aBooleanExpressionOrBlock value ifFalse:
			[AssertionFailure signal: 'Assertion failed']]
]

{ #category : #'printf logging' }
CCGClass >> f: logFilename open: mode [
	"Simulate a FILE stream by answering a transcript.
	 Can be used with the f:printf: method."
	<doNotGenerate>
	^true
		ifTrue: [(TranscriptStream on: (String new: 100000))
					openLabel: logFilename;
					yourself]
		ifFalse: [self coInterpreter transcript]
]

{ #category : #'memory access' }
CCGClass >> fetchSingleFloatAtPointer: pointer into: aFloat [
	"This gets implemented by Macros in C, where its types will also be checked.
	 pointer is a raw address, and aFloat is a 32-bit single precision float."
	<doNotGenerate>

	^self fetchSingleFloatAt: pointer into: aFloat
]

{ #category : #'memory access' }
CCGClass >> floatAtPointer: pointer [
	<doNotGenerate>
	self halt.
]

{ #category : #'memory access' }
CCGClass >> floatAtPointer: pointer put: value [
	<doNotGenerate>
	self halt.
]

{ #category : #'C library simulation' }
CCGClass >> free: pointer [
	<doNotGenerate>
	"Do nothing"
]

{ #category : #'memory access' }
CCGClass >> int16AtPointer: pointer [
	"This gets implemented by Macros in C, where its types will also be checked.
	 pointer is a raw address, and the result is an 16 bit integer."
	<doNotGenerate>

	^self shortAt: pointer
]

{ #category : #'memory access' }
CCGClass >> int16AtPointer: pointer put: value [
	"This gets implemented by Macros in C, where its types will also be checked.
	 pointer is a raw address, and the result is an 16 bit integer."
	<doNotGenerate>

	^self shortAt: pointer put: value
]

{ #category : #'memory access' }
CCGClass >> int32AtPointer: pointer [
	"This gets implemented by Macros in C, where its types will also be checked.
	 pointer is a raw address, and the result is an 32 bit integer."
	<doNotGenerate>

	^self longAt: pointer
]

{ #category : #'memory access' }
CCGClass >> int32AtPointer: pointer put: value [
	"This gets implemented by Macros in C, where its types will also be checked.
	 pointer is a raw address, and the result is an 32 bit integer."
	<doNotGenerate>

	^self longAt: pointer put: value
]

{ #category : #'memory access' }
CCGClass >> int64AtPointer: pointer [
	"This gets implemented by Macros in C, where its types will also be checked.
	 pointer is a raw address, and the result is the width of a machine word."
	<doNotGenerate>

	^self halt
]

{ #category : #'memory access' }
CCGClass >> int64AtPointer: pointer put: longValue [
	"This gets implemented by Macros in C, where its types will also be checked.
	 pointer is a raw address, and longValue is the width of a machine word."
	<doNotGenerate>

	^self halt.
]

{ #category : #'memory access' }
CCGClass >> int8AtPointer: pointer [
	"This gets implemented by Macros in C, where its types will also be checked.
	 pointer is a raw address, and the result is an 16 bit integer."
	<doNotGenerate>

	^self at: pointer
]

{ #category : #'memory access' }
CCGClass >> int8AtPointer: pointer put: value [
	"This gets implemented by Macros in C, where its types will also be checked.
	 pointer is a raw address, and the result is an 16 bit integer."
	<doNotGenerate>

	^self at: pointer put: value
]

{ #category : #testing }
CCGClass >> isCurrentImageFacade [
	^false
]

{ #category : #'plugin support' }
CCGClass >> isInterpreterProxy [
	<doNotGenerate>
	"Return false since I am a real Interpreter simulation"
	^false
]

{ #category : #'hack compatibility' }
CCGClass >> localNameFor: aString [
	<doNotGenerate>
	^(Smalltalk classNamed: #FileSystem)
		ifNotNil: [:fs| (fs disk pathFromString: aString) basename]
		ifNil: [FileDirectory default localNameFor: aString]
]

{ #category : #'memory access' }
CCGClass >> long64AtPointer: pointer [
	"This gets implemented by Macros in C, where its types will also be checked.
	 pointer is a raw address, and the result is the width of a machine word."
	<doNotGenerate>

	^self halt
]

{ #category : #'memory access' }
CCGClass >> long64AtPointer: pointer put: longValue [
	"This gets implemented by Macros in C, where its types will also be checked.
	 pointer is a raw address, and longValue is the width of a machine word."
	<doNotGenerate>

	^self halt.
]

{ #category : #'memory access' }
CCGClass >> longAtPointer: pointer [
	"This gets implemented by Macros in C, where its types will also be checked.
	 pointer is a raw address, and the result is the width of a machine word."
	<doNotGenerate>

	^self longAt: pointer
]

{ #category : #'memory access' }
CCGClass >> longAtPointer: pointer put: longValue [
	"This gets implemented by Macros in C, where its types will also be checked.
	 pointer is a raw address, and longValue is the width of a machine word."
	<doNotGenerate>

	^self longAt: pointer put: longValue
]

{ #category : #'simulation support' }
CCGClass >> majorVersion [
	"This is implemented in sqVirtualMachine.c, so this form is for simulation only."
	<doNotGenerate>
	^self class vmProxyMajorVersion
]

{ #category : #'C library simulation' }
CCGClass >> malloc: size [
	<doNotGenerate>
	^ByteArray new: size
]

{ #category : #'C library simulation' }
CCGClass >> memcpy: dest _: src _: bytes [
	<doNotGenerate>
	"implementation of memcpy(3). N.B. If ranges overlap, must use memmove."
	| getBlock setBlock source destination |

	source := src isVMSimulationAddress
		ifTrue: [src asInteger]
		ifFalse: [src].
	destination := dest isVMSimulationAddress
		ifTrue: [dest asInteger]
		ifFalse: [dest].
	(source isInteger and: [destination isInteger]) ifTrue:
		[ self deny: ((destination <= source and: [destination + bytes > source])
					or: [source <= destination and: [source + bytes > destination]])].

	"Determine the source and destination access blocks based on the parameter type"
	getBlock := source isCollection ifTrue: 
		[source isString ifTrue: 
			"basicAt: answers integers"
			[[ :idx | source basicAt: idx]]
		ifFalse: 
			[source class == ByteArray ifTrue: 
				[[ :idx | source at: idx]]]]
	ifFalse: 
		[source isInteger ifTrue: 
			[[ :idx | self byteAt: source + idx - 1]]
		ifFalse: 
			[source isCArray ifTrue:
				[[ :idx | source at: idx - 1]]]].
	getBlock ifNil: [self error: 'unhandled type of source string'].
	setBlock := destination isCollection ifTrue: 
		[destination isString ifTrue:
			"basicAt:put: stores integers"
			[[ :idx | destination basicAt: idx put: (getBlock value: idx)]] 
		ifFalse: 
			[destination class == ByteArray ifTrue: 
				[[ :idx | destination at: idx put: (getBlock value: idx)]]]]
	ifFalse: 
		[destination isInteger ifTrue:
			[[ :idx | self byteAt: destination + idx - 1 put: (getBlock value: idx)]]
		ifFalse:
			[destination isCArray ifTrue:
				[[ :idx | destination at: idx - 1 put: (getBlock value: idx)]]]].
	setBlock ifNil: [self error: 'unhandled type of destination string'].
	1 to: bytes do: setBlock.

	^destination
]

{ #category : #'C library simulation' }
CCGClass >> memmove: destAddress _: sourceAddress _: bytes [
	<doNotGenerate>
	| dst src  |
	dst := destAddress asInteger.
	src := sourceAddress asInteger.
	"Emulate the c library memmove function"
	self assert: bytes \\ 4 = 0.
	destAddress > sourceAddress
		ifTrue:
			[bytes - 4 to: 0 by: -4 do:
				[:i| self longAt: dst + i put: (self longAt: src + i)]]
		ifFalse:
			[0 to: bytes - 4 by: 4 do:
				[:i| self longAt: dst + i put: (self longAt: src + i)]]
]

{ #category : #'simulation support' }
CCGClass >> minorVersion [
	"This is implemented in sqVirtualMachine.c, so this form is for simulation only."
	<doNotGenerate>
	^self class vmProxyMinorVersion
]

{ #category : #'translation support' }
CCGClass >> numElementsIn: anArray [
	<cmacro: '(anArray) (sizeof(anArray)/sizeof(anArray[0]))'>
	^anArray size
]

{ #category : #accessing }
CCGClass >> objectRepresentationClass [
	<doNotGenerate>
	^self class objectRepresentationClass
]

{ #category : #'oop comparison' }
CCGClass >> oop: anOop isGreaterThan: otherOop [
	"Compare two oop values, treating them as object memory locations; i.e. use unsigned comparisons.
	 Use a macro, instead of #cCoerce:to: to provide fast simulation and inline code in conditionals,
	 since the inliner doesn't inline in condtionals."
	<cmacro: '(anOop,otherOop) ((usqInt)(anOop) > (usqInt)(otherOop))'>
	^anOop > otherOop
]

{ #category : #'oop comparison' }
CCGClass >> oop: anOop isGreaterThan: baseOop andLessThan: limitOop [
	"Compare two oop values, treating them as object memory locations; i.e. use unsigned comparisons.
	 Use a macro, instead of #cCoerce:to: to provide fast simulation and inline code in conditionals,
	 since the inliner doesn't inline in condtionals."
	<cmacro: '(anOop,baseOop,limitOop) ((usqInt)(anOop) > (usqInt)(baseOop) && (usqInt)(anOop) < (usqInt)(limitOop))'>
	^anOop > baseOop and: [anOop < limitOop]
]

{ #category : #'oop comparison' }
CCGClass >> oop: anOop isGreaterThanOrEqualTo: otherOop [
	"Compare two oop values, treating them as object memory locations; i.e. use unsigned comparisons.
	 Use a macro, instead of #cCoerce:to: to provide fast simulation and inline code in conditionals,
	 since the inliner doesn't inline in condtionals."
	<cmacro: '(anOop,otherOop) ((usqInt)(anOop) >= (usqInt)(otherOop))'>
	^anOop >= otherOop
]

{ #category : #'oop comparison' }
CCGClass >> oop: anOop isGreaterThanOrEqualTo: baseOop andLessThan: limitOop [
	"Compare two oop values, treating them as object memory locations; i.e. use unsigned comparisons.
	 Use a macro, instead of #cCoerce:to: to provide fast simulation and inline code in conditionals,
	 since the inliner doesn't inline in condtionals."
	<cmacro: '(anOop,baseOop,limitOop) ((usqInt)(anOop) >= (usqInt)(baseOop) && (usqInt)(anOop) < (usqInt)(limitOop))'>
	^anOop >= baseOop and: [anOop < limitOop]
]

{ #category : #'oop comparison' }
CCGClass >> oop: anOop isGreaterThanOrEqualTo: baseOop andLessThanOrEqualTo: limitOop [
	"Compare two oop values, treating them as object memory locations; i.e. use unsigned comparisons.
	 Use a macro, instead of #cCoerce:to: to provide fast simulation and inline code in conditionals,
	 since the inliner doesn't inline in condtionals."
	<cmacro: '(anOop,baseOop,limitOop) ((usqInt)(anOop) >= (usqInt)(baseOop) && (usqInt)(anOop) <= (usqInt)(limitOop))'>
	^anOop >= baseOop and: [anOop <= limitOop]
]

{ #category : #'oop comparison' }
CCGClass >> oop: anOop isLessThan: otherOop [
	"Compare two oop values, treating them as object memory locations; i.e. use unsigned comparisons.
	 Use a macro, instead of #cCoerce:to: to provide fast simulation and inline code in conditionals,
	 since the inliner doesn't inline in condtionals."
	<cmacro: '(anOop,otherOop) ((usqInt)(anOop) < (usqInt)(otherOop))'>
	^anOop < otherOop
]

{ #category : #'oop comparison' }
CCGClass >> oop: anOop isLessThanOrEqualTo: otherOop [
	"Compare two oop values, treating them as object memory locations; i.e. use unsigned comparisons.
	 Use a macro, instead of #cCoerce:to: to provide fast simulation and inline code in conditionals,
	 since the inliner doesn't inline in condtionals."
	<cmacro: '(anOop,otherOop) ((usqInt)(anOop) <= (usqInt)(otherOop))'>
	^anOop <= otherOop
]

{ #category : #'memory access' }
CCGClass >> oopForPointer: pointerOrSurrogate [
	"This gets implemented by Macros in C, where its types will also be checked.
	 oop is the width of a machine word, and pointer is a raw address."
	<doNotGenerate>
	^pointerOrSurrogate asInteger
]

{ #category : #'memory access' }
CCGClass >> pointerAtPointer: pointer [
	"This gets implemented by Macros in C, where its types will also be checked.
	 pointer is a raw address, and the result is the width of a machine word."
	<doNotGenerate>

	^self longAt: pointer
]

{ #category : #'memory access' }
CCGClass >> pointerAtPointer: pointer put: value [
	"This gets implemented by Macros in C, where its types will also be checked.
	 pointer is a raw address, and the result is the width of a machine word."
	<doNotGenerate>

	^self longAt: pointer put: value
]

{ #category : #'translation support' }
CCGClass >> pointerForOop: oop [
	"This gets implemented by Macros in C, where its types will also be checked.
	 oop is the width of a machine word, and pointer is a raw address."
	<doNotGenerate>

	^oop
]

{ #category : #'simulation support' }
CCGClass >> promptHex: string [
	<doNotGenerate>
	| s |
	s := UIManager default request: string, ' (hex)'.
	s := s withBlanksTrimmed.
	^(s notEmpty and: ['-+0123456789abcdefABCDEF' includes: s first]) ifTrue:
		[(s includes: $r)
			ifTrue:
				[Number readFrom: s readStream]
			ifFalse:
				[(#('0x' '-0x') detect: [:prefix| s beginsWith: prefix] ifNone: []) ifNotNil:
					[:prefix|
					s := s allButFirst: prefix size.
					prefix first = $- ifTrue: [s := '-', s]].
				Integer readFrom: s readStream base: 16]]
]

{ #category : #'simulation support' }
CCGClass >> promptNum: string [
	<doNotGenerate>
	| s |
	s := UIManager default request: string, ' (dec)'.
	s := s withBlanksTrimmed.
	^s notEmpty ifTrue:
		[Number readFrom: s readStream]
]

{ #category : #arithmetic }
CCGClass >> safe: signedInteger mod: positiveModulus [
	<inline>
	| remainder |
	^(remainder := signedInteger \\ positiveModulus) < 0
		ifTrue: [remainder + positiveModulus]
		ifFalse: [remainder]
]

{ #category : #'memory access' }
CCGClass >> singleFloatAtPointer: pointer [
	<doNotGenerate>
	self halt.
]

{ #category : #'memory access' }
CCGClass >> singleFloatAtPointer: pointer put: value [
	<doNotGenerate>
	self halt.
]

{ #category : #'translation support' }
CCGClass >> sizeof: objectSymbolOrClass [
	<doNotGenerate>
	| index |
	objectSymbolOrClass isInteger ifTrue:
		[^self class objectMemoryClass wordSize].
	(#(usqInt sqInt) includes: objectSymbolOrClass) ifTrue: [^self class objectMemoryClass bytesPerOop].
	objectSymbolOrClass isSymbol ifTrue:
		[(objectSymbolOrClass last == $*
		 or: [#(#long #'unsigned long' #'sqIntptr_t'  #'usqIntptr_t' #'size_t') includes: objectSymbolOrClass]) ifTrue:
			[^self class objectMemoryClass wordSize].
		index := #(	#sqLong #usqLong #double
					#int #'unsigned int' #float
					#short #'unsigned short'
					#char #'unsigned char' #'signed char')
						indexOf: objectSymbolOrClass
						ifAbsent:
							[self error: 'unrecognized C type name'].
		^#(8 8 8
			4 4 4
			2 2
			1 1 1) at: index].
	^(objectSymbolOrClass isBehavior
		ifTrue: [objectSymbolOrClass]
		ifFalse: [objectSymbolOrClass class])
			alignedByteSizeOf: objectSymbolOrClass
			forClient: self
]

{ #category : #'simulation support' }
CCGClass >> sqLowLevelMFence [
	<doNotGenerate>
	"A no-op in the simulator"
]

{ #category : #'memory access' }
CCGClass >> storeFloatAtPointer: pointer from: aFloat [
	"This gets implemented by Macros in C, where its types will also be checked.
	 pointer is a raw address, and aFloat is a 64-bit double precision float."
	<doNotGenerate>

	^self storeFloatAt: pointer from: aFloat
]

{ #category : #'memory access' }
CCGClass >> storeSingleFloatAtPointer: pointer from: aFloat [
	"This gets implemented by Macros in C, where its types will also be checked.
	 pointer is a raw address, and aFloat is a 32-bit single precision float."
	<doNotGenerate>

	^self storeSingleFloatAt: pointer from: aFloat
]

{ #category : #'C library simulation' }
CCGClass >> strcat: aString _: bString [
	<doNotGenerate>
	"implementation of strcat(3)"
	^(self asString: aString), (self asString: bString)
]

{ #category : #'C library extensions' }
CCGClass >> stretch: s1 cat: s2 [
	<var: 's1' type: #'char *'>
	<var: 's2' type: #'char *'>
	| ns |
	<var: 'ns' type: #'char *'>
	^self
		cCode:
			[ns := self malloc: (self strlen: s1) + (self strlen: s2) + 2.
			 self strcpy: ns _: s1.
			 self strcat: ns  _: s2]
		inSmalltalk: [self strcat: s1  _: s2]
]

{ #category : #'C library simulation' }
CCGClass >> strlen: aCString [
	"Simulate strlen(3)"
	<doNotGenerate>
	| len |

	aCString isCArray ifTrue:
		[len := 0.
		 [(aCString at: len) = 0 ifTrue: [^len].
		 len := len + 1] repeat]
	ifFalse:
		[aCString isString ifTrue: 
			[^aCString size]
		ifFalse:
			[aCString class == ByteArray ifTrue: [
				"ByteArrays may be 0 terminated or the correct length (in the simulator)"
				len := 0.
				[(len = aCString size or: [(aCString at: len+1) = 0]) ifTrue: [^len].
				len := len + 1] repeat]]].
	"Must be an address"
	len := 0.
	[(self byteAt: aCString + len) = 0 ifTrue: [^len].
	len := len + 1] repeat
]

{ #category : #'C library simulation' }
CCGClass >> strncmp: aString _: bString _: n [
	<doNotGenerate>
	"implementation of strncmp(3)"
	bString isString
		ifTrue:
			[1 to: n do:
				[:i| | v |
				 v := (aString basicAt: i) - (bString basicAt: i).
				 v ~= 0 ifTrue: [^v]]]
		ifFalse:
			[1 to: n do:
				[:i| | v |
				 v := (aString basicAt: i) - (self byteAt: bString + i - 1).
				 v ~= 0 ifTrue: [^v]]].
	^0
]

{ #category : #'C library simulation' }
CCGClass >> strncpy: dest _: src _: n [
	<doNotGenerate>
	"implementation of strncpy(3).
	 See e.g. https://manpages.debian.org/stretch/manpages-dev/strncpy.3.en.html
	 The C version always takes an address; the simulation allows a String, ByteArray,
	 CArray or address within the simulation object memory (Positive Integer)"
	| getBlock setBlock count |
	count := n.
	"Determine the source and destination access blocks based on the parameter type"
	getBlock := src isCollection
					ifTrue:
						[count := count min: src size.
						 src isString
							ifTrue: [[ :idx | src basicAt: idx]] "basicAt: answers integers"
							ifFalse:
								[src class == ByteArray ifTrue:
									[[ :idx | src at: idx]]]]
					ifFalse:
						[src isInteger
							ifTrue: [[ :idx | self byteAt: src + idx - 1]]
							ifFalse:
								[src isCArray ifTrue:
									[[ :idx | src at: idx - 1]]]].
	getBlock ifNil: [self error: 'unhandled type of source string'].
	setBlock := dest isCollection
					ifTrue:
						[dest isString
							ifTrue: [[ :idx | dest basicAt: idx put: (getBlock value: idx)]] "basicAt:put: stores integers"
							ifFalse:
								[dest class == ByteArray ifTrue:
									[[ :idx | dest at: idx put: (getBlock value: idx)]]]]
					ifFalse:
						[dest isInteger ifTrue: 
							[[ :idx | self byteAt: dest + idx - 1 put: (getBlock value: idx)]]].
	setBlock ifNil: [self error: 'unhandled type of destination string'].
	1 to: count do: setBlock.
	"SVr4, 4.3BSD, C89, C99 require the remainder of the buffer be filled with nulls"
	getBlock := [:idx| 0].
	count + 1 to: n do: setBlock.
	^dest
]

{ #category : #'hack compatibility' }
CCGClass >> uiProcess [
	<doNotGenerate>
	^(Smalltalk classNamed: #Project)
		ifNotNil: [:project| Project uiProcess] "Squeak"
		ifNil: [UIManager default uiProcess] "Pharo"
]

{ #category : #'memory access' }
CCGClass >> uint16AtPointer: pointer [
	"This gets implemented by Macros in C, where its types will also be checked.
	 pointer is a raw address, and the result is an 16 bit integer."
	<doNotGenerate>

	^self shortAt: pointer
]

{ #category : #'memory access' }
CCGClass >> uint16AtPointer: pointer put: value [
	"This gets implemented by Macros in C, where its types will also be checked.
	 pointer is a raw address, and the result is an 16 bit integer."
	<doNotGenerate>

	^self shortAt: pointer put: value
]

{ #category : #'memory access' }
CCGClass >> uint32AtPointer: pointer [
	"This gets implemented by Macros in C, where its types will also be checked.
	 pointer is a raw address, and the result is an 32 bit integer."
	<doNotGenerate>

	^self longAt: pointer
]

{ #category : #'memory access' }
CCGClass >> uint32AtPointer: pointer put: value [
	"This gets implemented by Macros in C, where its types will also be checked.
	 pointer is a raw address, and the result is an 32 bit integer."
	<doNotGenerate>

	^self longAt: pointer put: value
]

{ #category : #'memory access' }
CCGClass >> uint64AtPointer: pointer [
	"This gets implemented by Macros in C, where its types will also be checked.
	 pointer is a raw address, and the result is the width of a machine word."
	<doNotGenerate>

	^self halt
]

{ #category : #'memory access' }
CCGClass >> uint64AtPointer: pointer put: longValue [
	"This gets implemented by Macros in C, where its types will also be checked.
	 pointer is a raw address, and longValue is the width of a machine word."
	<doNotGenerate>

	^self halt.
]

{ #category : #'memory access' }
CCGClass >> uint8AtPointer: pointer [
	"This gets implemented by Macros in C, where its types will also be checked.
	 pointer is a raw address, and the result is an 16 bit integer."
	<doNotGenerate>

	^self at: pointer
]

{ #category : #'memory access' }
CCGClass >> uint8AtPointer: pointer put: value [
	"This gets implemented by Macros in C, where its types will also be checked.
	 pointer is a raw address, and the result is an 16 bit integer."
	<doNotGenerate>

	^self at: pointer put: value
]

{ #category : #simulation }
CCGClass >> unalignedAccessError [
	^self error: 'unaligned access'
]

{ #category : #'debug support' }
CCGClass >> unreachable [
	<inline: true>
	self error: 'UNREACHABLE'
]

{ #category : #'hack compatibility' }
CCGClass >> vmPath [
	<doNotGenerate>
	^(Smalltalk classNamed: #VirtualMachine)
		ifNotNil: [:project| Smalltalk vm path] "Squeak"
		ifNil: [Smalltalk vmPath] "Pharo"
]

{ #category : #'hack compatibility' }
CCGClass >> vmPathSize [
	<doNotGenerate>
	^self vmPath size
]
