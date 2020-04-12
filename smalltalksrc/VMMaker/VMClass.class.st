"
I am an abstract superclass for all classes in the VM that want to maintain a source timeStamp.  I am also the holder of the InitializationOptions class variable which holds options such as which JIT or which memory manager to use when creating or generating a VM.
"
Class {
	#name : #VMClass,
	#superclass : #CCGClass,
	#category : #'VMMaker-Translation to C'
}

{ #category : #translation }
VMClass class >> ancilliaryClasses [
	"Answer any extra classes to be included in the translation."
	^{}
]

{ #category : #translation }
VMClass class >> apiExportHeaderName [
	"VM classesd that want to generate an api export header override this."
	^nil
]

{ #category : #'adding/removing methods' }
VMClass class >> basicRemoveSelector: aSelector [
	"Override to update the timeStamp"
	^(super basicRemoveSelector: aSelector) ifNotNil:
		[:oldMethod| self touch. oldMethod]
]

{ #category : #translation }
VMClass class >> cogMethodClass: options [
	^(options at: #NewspeakVM ifAbsent: [false])
		ifTrue: [NewspeakCogMethod]
		ifFalse: [CogMethod]
]

{ #category : #'accessing class hierarchy' }
VMClass class >> cogitClass [
	"Answer the cogitClass in effect.  Ensure that StackInterpreter has a nil cogitClass."
	(self isInterpreterClass and: [self hasCogit not]) ifTrue:
		[^nil].
	^Smalltalk classNamed: (InitializationOptions
								at: #Cogit
								ifAbsent: [#StackToRegisterMappingCogit])
]

{ #category : #'accessing class hierarchy' }
VMClass class >> coreInterpreterClass [
	"While the interpreterClass/vmClass for translation may be
	 a subclass that holds a few primitives we want the actual
	 interpreter name at the head of the generated file."
	^((name endsWith: 'Primitives')
	   and: [name beginsWith: superclass name])
		ifTrue: [superclass]
		ifFalse: [self]
]

{ #category : #translation }
VMClass class >> declareC: arrayOfVariableNames as: aCType in: aCCodeGenerator [
	"Declare the variables in arrayOfVariableNames with the given type."

	arrayOfVariableNames
		do: [:varName | aCCodeGenerator var: varName type: aCType]
]

{ #category : #translation }
VMClass class >> declareCAsOop: arrayOfVariableNames in: aCCodeGenerator [
	"Declare the variables in arrayOfVariableNames with type representing position in object memory."

	arrayOfVariableNames do:
		[:varName| aCCodeGenerator var: varName type: #usqInt]
]

{ #category : #translation }
VMClass class >> declareCAsUSqLong: arrayOfVariableNames in: aCCodeGenerator [
	"Declare the variables in arrayOfVariableNames with type representing position in object memory."

	arrayOfVariableNames do:
		[:varName| aCCodeGenerator var: varName type: #usqLong]
]

{ #category : #translation }
VMClass class >> declareCVarsIn: aCCodeGenerator [ 
	"Declare any additional variables and/or add type declarations for existing variables."
	aCCodeGenerator
		var: #expensiveAsserts
		declareC: 'char expensiveAsserts = 0'
]

{ #category : #translation }
VMClass class >> declareInterpreterVersionIn: aCCodeGenerator defaultName: defaultName [
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
VMClass class >> defaultIntegerBaseInDebugger [
	"DefaultBase := 16."
	"DefaultBase := 10."
	DefaultBase isNil ifTrue: [DefaultBase := 16].
	^DefaultBase
]

{ #category : #'accessing class hierarchy' }
VMClass class >> defaultObjectMemoryClass [
	"Default for all-in-one VMs where the interpreter inherits from the object memory."
	^nil
]

{ #category : #'as yet unclassified' }
VMClass class >> exportHeaders [

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
VMClass class >> getVMMaker [
	^Notification new tag: #getVMMaker; signal
]

{ #category : #'accessing class hierarchy' }
VMClass class >> hasCogit [
	^false
]

{ #category : #translation }
VMClass class >> implicitReturnTypeFor: aSelector [
	"Answer the return type for methods that don't have an explicit return."
	^#sqInt
]

{ #category : #initialization }
VMClass class >> initializationOptions [
	^InitializationOptions
]

{ #category : #initialization }
VMClass class >> initialize [
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
VMClass class >> initializeForPlugins: optionsDictionaryOrArray [
	"Do a default initialization, suitable for generating plugin sources."
	StackInterpreterSimulator
		initializeWithOptions: optionsDictionaryOrArray
		objectMemoryClass: ObjectMemory
]

{ #category : #initialization }
VMClass class >> initializeMiscConstants [
	"Falsify the `what type of VM is this?' flags that are defined in the various interp.h files.
	 Subclass implementations need to include a super initializeMiscConstants"

	| omc |
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

{ #category : #initialization }
VMClass class >> initializePrimitiveErrorCodes [
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
VMClass class >> initializeWithOptions: optionsDictionaryOrArray [
	"Initialize the receiver, typically initializing class variables. Initialize any class variables
	 whose names occur in optionsDictionary with the corresponding values there-in."
	InitializationOptions := optionsDictionaryOrArray isArray
								ifTrue: [Dictionary newFromPairs: optionsDictionaryOrArray]
								ifFalse: [optionsDictionaryOrArray].

	ExpensiveAsserts := InitializationOptions at: #ExpensiveAsserts ifAbsent: [false]
]

{ #category : #'accessing class hierarchy' }
VMClass class >> interpreterClass [
	^self isInterpreterClass ifTrue: [self]
]

{ #category : #accessing }
VMClass class >> interpreterVersion [ 
	^ self subclassResponsibility
]

{ #category : #translation }
VMClass class >> isAcceptableAncilliaryClass: aClass [
	^true
]

{ #category : #translation }
VMClass class >> isAccessor: aSelector [
	"Answer if aSelector is simply an accessor method for one of our fields.
	 Answer false by default.  VMStructType classes redefine this appropriately."
	^false
]

{ #category : #translation }
VMClass class >> isCogitClass [
	"The various Cogit classes override this."
	^false
]

{ #category : #translation }
VMClass class >> isInterpreterClass [
	"The various Interpreter classes override this."
	^false
]

{ #category : #translation }
VMClass class >> isNonArgumentImplicitReceiverVariableName: aString [
	^false
]

{ #category : #translation }
VMClass class >> isPluginClass [
	"InterpreterPlugin class override this."
	^false
]

{ #category : #translation }
VMClass class >> isStructClass [
	"The various VMStructType classes override this."
	^false
]

{ #category : #accessing }
VMClass class >> memoryManagerVersion [ 
	^ self subclassResponsibility
]

{ #category : #translation }
VMClass class >> monticelloDescription [
	"Answer the Monticello version of the packlage containing the receiver.
	 This is a hook to allow subclasses to expand upon the default monticello description."
	^CCodeGenerator monticelloDescriptionFor: self
]

{ #category : #translation }
VMClass class >> mustBeGlobal: var [
	"Answer if a variable must be global and exported.  Used for inst vars that are accessed from VM support code."

	^var = #expensiveAsserts
]

{ #category : #translation }
VMClass class >> noteCompilationOf: aSelector meta: isMeta [
	"note the recompiliation by resetting the timeStamp "
	timeStamp := Time totalSeconds.
	^super noteCompilationOf: aSelector meta: isMeta
]

{ #category : #'accessing class hierarchy' }
VMClass class >> objectMemoryClass [
	InitializationOptions ifNil:
		[^self defaultObjectMemoryClass].
	^Smalltalk at: (InitializationOptions
					at: #ObjectMemory
					ifAbsent: [^self defaultObjectMemoryClass])
]

{ #category : #'accessing class hierarchy' }
VMClass class >> objectRepresentationClass [
	^self objectMemoryClass objectRepresentationClass
]

{ #category : #'as yet unclassified' }
VMClass class >> openCogMultiWindowBrowser [
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

{ #category : #'as yet unclassified' }
VMClass class >> openCogSpurMultiWindowBrowser [
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

{ #category : #'as yet unclassified' }
VMClass class >> openCogTestsMultiWindowBrowser [
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

{ #category : #'as yet unclassified' }
VMClass class >> openCogitMultiWindowBrowser [
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

{ #category : #'as yet unclassified' }
VMClass class >> openObjectMemoriesInterpretersBrowser [
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

{ #category : #'as yet unclassified' }
VMClass class >> openSpurMultiWindowBrowser [
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

{ #category : #translation }
VMClass class >> prepareToBeAddedToCodeGenerator: aCCodeGenerator [ 
	"Hook for translation.  e.g. allows a subclass to override its
	 superclass's methods by deleting them before it adds its own."
]

{ #category : #translation }
VMClass class >> requiredMethodNames: options [
	"Answer a list of method names that should be retained for export or other
	 support reasons.  These are typically entry-points that unless explicitly noted
	 will be deleted by the code generator since it will assume these are not used."
	^#()
]

{ #category : #translation }
VMClass class >> shouldGenerateDeadCode [
	"Answer if the code generator should generate dead code, e.g. in false ifTrue: [dead] ifFalse: [live].
	 This *may* be useful in debugging (see CCodeGenerator>>nilOrBooleanConstantReceiverOf: et al).
	 But by default we answer false."

	^false
]

{ #category : #translation }
VMClass class >> shouldGenerateTypedefFor: aStructClass [
	"Hack to work-around multiple definitions.  Sometimes a type has been defined in an include."
	^aStructClass ~~ VMCallbackContext
]

{ #category : #translation }
VMClass class >> shouldIncludeMethodForSelector: selector [
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
VMClass class >> simulatorClass [
	"For running from Smalltalk - answer a class that can be used to simulate the receiver."

	^self
]

{ #category : #translation }
VMClass class >> specialValueForConstant: constantName default: defaultValue [
	^nil
]

{ #category : #translation }
VMClass class >> staticallyResolvePolymorphicSelector: aSelectorSymbol [
	^((self name select: [:ea| ea isUppercase]), '_', aSelectorSymbol) asSymbol
]

{ #category : #translation }
VMClass class >> timeStamp [
	^timeStamp ifNil:[0]
]

{ #category : #translation }
VMClass class >> touch [
	"Reset the timeStamp"
	"Smalltalk allClasses select:
		[:c| (c category includesSubString: 'VMMaker-JIT') ifTrue: [c touch]]"
	"InterpreterPlugin withAllSubclassesDo:[:pl| pl touch]"
	timeStamp := Time totalSeconds
]

{ #category : #translation }
VMClass class >> translationClass [
	"Return the class to use as the interpreterCLass when translating.  For the all-in-one
	 VMs that inherit from ObjectMemory this is the receiver.  But for the separate VMs
	 where most primitives are in a subclass it will be the subclass with the primitives."
	^self
]

{ #category : #translation }
VMClass class >> typeForSelf [
	"Answer the type to give self if appropriate, or nil if not."
	^nil
]

{ #category : #translation }
VMClass class >> writeVMHeaderTo: aStream bytesPerWord: bytesPerWord generator: aCCodeGenerator [
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

{ #category : #'C library simulation' }
VMClass >> malloc: size [
	<doNotGenerate>
	^CArrayAccessor on: (ByteArray new: size)
]
