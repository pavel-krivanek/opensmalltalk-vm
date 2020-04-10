Extension { #name : #Integer }

{ #category : #'*VMMaker-interpreter simulator' }
Integer >> addBreakpoint: address [
	^{self. address}
]

{ #category : #'*VMMaker-interpreter simulator' }
Integer >> asC_int [
	^self >= 0
		ifTrue: [self bitAnd: 16rFFFFFFFF]
		ifFalse: [(self bitAnd: 16rFFFFFFFF) - 16r100000000]
]

{ #category : #'*VMMaker-interpreter simulator' }
Integer >> asC_unsigned_int [
	^self bitAnd: 16rFFFFFFFF
]

{ #category : #'*VMMaker-interpreter simulator' }
Integer >> asPositiveIntegerObj [
	"This is a SmartSyntaxPlugin convenience, invented with little thought for simulation (grrr).
	  In the VM this is equivalent to
		interpreterProxy methodReturnValue: (interpreterProxy positive32BitIntegerFor: self)
	 but if a plugin is being developed I /think/ it is just
		^self
	 So search the stack to discover what context it is being used in."
	(thisContext findContextSuchThat: [:ctxt| ctxt receiver isInterpreterPlugin]) ifNotNil:
		[:ctxt| | interpreter |
		interpreter := ctxt receiver getInterpreter.
		interpreter methodReturnValue: (interpreter positive32BitIntegerFor: self)].
	^self
]

{ #category : #'*VMMaker-interpreter simulator' }
Integer >> asUnsignedLong [
	self assert: self >= 0.
	^self
]

{ #category : #'*VMMaker-interpreter simulator' }
Integer >> asUnsignedLongLong [
	self assert: self >= 0.
	^self
]

{ #category : #'*VMMaker-interpreter simulator' }
Integer >> asVoidPointer [
	^self
]

{ #category : #'*VMMaker-plugin generation' }
Integer class >> ccg: cg prolog: aBlock expr: aString index: anInteger [

	^cg ccgLoad: aBlock expr: aString asKindOfIntegerFrom: anInteger
]

{ #category : #'*VMMaker-interpreter simulator' }
Integer >> coerceTo: cTypeString sim: interpreter [

	| unitSize |
	cTypeString last = $* ifTrue:  "C pointer"
		[unitSize := cTypeString caseOf: {
		[#'char *'] -> [1].
		[#'short *'] -> [2].
		[#'int *'] -> [4].
		[#'long long *'] -> [8].
		[#'float *'] -> [^CFloatArray basicNew interpreter: interpreter address: self unitSize: 4; yourself].
		[#'double *'] -> [^CFloatArray basicNew interpreter: interpreter address: self unitSize: 8; yourself].
		[#'unsigned *'] -> [4].
		[#'unsigned int *'] -> [4].
		[#'unsigned char *'] -> [1].
		[#'signed char *'] -> [1].
		[#'unsigned short *'] -> [2].
		[#'unsigned long long *'] -> [8].
		[#'oop *'] -> [interpreter objectMemory bytesPerOop].
		}
		otherwise: [interpreter objectMemory wordSize].
		^CArray basicNew
			interpreter: interpreter address: self unitSize: unitSize;
			yourself].
	^self  "C number (int, char, float, etc)"
]

{ #category : #'*VMMaker-printing' }
Integer >> hex8 [
	"Print the receiver in base 16 with prefixed base, using at least 8 digits.
	 DO NOT CHANGE THIS!  The Cog VMMaker depends on this.
	 Consider using storeStringBase: 16 length: 11 padded: true instead."
	  "16r3333 hex8"
	| hex |
	hex := self hex.  "16rNNN"
	^hex size < 11
		ifTrue: [hex copyReplaceFrom: 4 to: 3
						 with: ('00000000' copyFrom: 1 to: 11-hex size)]
		ifFalse: [hex]
]

{ #category : #'*VMMaker-interpreter simulator' }
Integer >> isActiveBreakpoint [
	^true
]

{ #category : #'*VMMaker-interpreter simulator' }
Integer >> isBreakpointFor: address [
	^self = address
]

{ #category : #'*VMMaker-interpreter simulator' }
Integer >> menuPrompt [
	^' (', self hex, ')'
]

{ #category : #'*VMMaker-interpreter simulator' }
Integer >> removeBreakpoint: address [
	^nil
]

{ #category : #'*VMMaker-interpreter simulator' }
Integer >> signedIntFromChar [
	"Self is an unsigned 8-bit integer in twos-comp form"

	| shortBits |
	shortBits := self bitAnd: 16rFF.
	^(self bitAnd: 16r80) "sign bit" = 0
		ifTrue: [shortBits]
		ifFalse: [shortBits - 16r100]
]

{ #category : #'*VMMaker-interpreter simulator' }
Integer >> signedIntToChar [
	"Produces an 8-bit value in twos-comp form. Truncates if out-of-range as per a C cast"

	^self bitAnd: 16rFF
]

{ #category : #'*VMMaker-interpreter simulator' }
Integer >> singleStepRequiredToTriggerIn: aCogit [
	^self between: aCogit cogCodeBase and: aCogit methodZone limitZony
]
