Extension { #name : #ThreadSafeTranscript }

{ #category : #'*CCodeGenerator-Core' }
ThreadSafeTranscript >> crtab [
	self critical: [stream crtab]
]

{ #category : #'*CCodeGenerator-Core' }
ThreadSafeTranscript >> ensureCr [
	(stepContents notEmpty and: [stepContents last ~~ Character cr]) ifTrue:
		[ self nextPut: Character cr]
]

{ #category : #'*CCodeGenerator-Core' }
ThreadSafeTranscript >> next: anInteger put: anObject [
	"This is supposed to be a fucking WriteStream.  Why am I doing donkey work like this??"
	self critical: [stream next: anInteger put: anObject]
]
