// RUN: %clang_cc1 -fsyntax-only -verify -Wno-objc-root-class %s
// RUN: %clang_cc1 -x objective-c++ -fsyntax-only -verify -Wno-objc-root-class %s

@interface A {
  int X __attribute__((deprecated)); // expected-note 2 {{'X' has been explicitly marked deprecated here}}
}
+ (void)F __attribute__((deprecated)); // expected-note 2 {{'F' has been explicitly marked deprecated here}}
- (void)f __attribute__((deprecated)); // expected-note 4 {{'f' has been explicitly marked deprecated here}}
@end

@implementation A
+ (void)F __attribute__((deprecated))
{
  [self F]; // no warning, since the caller is also deprecated.
}

- (void)g
{
  X++;        // expected-warning{{'X' is deprecated}}
  self->X++;  // expected-warning{{'X' is deprecated}}
  [self f]; // expected-warning{{'f' is deprecated}}
}

- (void)f
{
  [self f]; // no warning, the caller is deprecated in its interface.
}
@end

@interface B: A
@end
  
@implementation B
+ (void)G
{
  [super F]; // expected-warning{{'F' is deprecated}}
}

- (void)g
{
  [super f]; // // expected-warning{{'f' is deprecated}}
}
@end

@protocol P
- (void)p __attribute__((deprecated)); // expected-note {{'p' has been explicitly marked deprecated here}}
@end

void t1(A *a)
{
  [A F]; // expected-warning{{'F' is deprecated}}
  [a f]; // expected-warning{{'f' is deprecated}}
}

void t2(id a)
{
  [a f];
}

void t3(A<P>* a)
{
  [a f]; // expected-warning{{'f' is deprecated}}
  [a p]; // expected-warning{{'p' is deprecated}}
} 

void t4(Class c)
{
  [c F];
}



@interface Bar 

@property (assign, setter = MySetter:) int FooBar __attribute__ ((deprecated)); // expected-note 2 {{'FooBar' has been explicitly marked deprecated here}}
- (void) MySetter : (int) value;
@end

int t5() {
  Bar *f;
  f.FooBar = 1;	   // expected-warning {{'FooBar' is deprecated}}
  return f.FooBar; // expected-warning {{'FooBar' is deprecated}}
}


__attribute ((deprecated))  
@interface DEPRECATED { // expected-note 2 {{'DEPRECATED' has been explicitly marked deprecated here}}
  @public int ivar; 
  DEPRECATED *ivar2; // no warning.
} 
- (int) instancemethod;
- (DEPRECATED *) meth; // no warning.
@property  int prop; 
@end

@interface DEPRECATED (Category) // no warning.
- (DEPRECATED *) meth2; // no warning.
@end

@interface DEPRECATED (Category2) // no warning.
@end

@implementation DEPRECATED (Category2) // expected-warning {{'DEPRECATED' is deprecated}}
@end

@interface NS : DEPRECATED  // expected-warning {{'DEPRECATED' is deprecated}}
@end


@interface Test2
@property int test2 __attribute__((deprecated)); // expected-note 2 {{property 'test2' is declared deprecated here}} expected-note 3 {{'test2' has been explicitly marked deprecated here}} \
						 // expected-note {{'setTest2:' has been explicitly marked deprecated here}}
@end

void test(Test2 *foo) {
  int x;
  x = foo.test2; // expected-warning {{'test2' is deprecated}}
  x = [foo test2]; // expected-warning {{'test2' is deprecated}}
  foo.test2 = x; // expected-warning {{'test2' is deprecated}}
  [foo setTest2: x]; // expected-warning {{'setTest2:' is deprecated}}
}

__attribute__((deprecated))
@interface A(Blah) // expected-error{{attributes may not be specified on a category}}
@end


typedef struct {
	int x;
} footype __attribute((deprecated)); // expected-note 2 {{'footype' has been explicitly marked deprecated here}}

@interface foo {
	footype a; // expected-warning {{'footype' is deprecated}}
	footype b __attribute((deprecated));
}
@property footype c; // expected-warning {{'footype' is deprecated}}
@property footype d __attribute((deprecated));
@end

// rdar://13569424
@interface NewI
+(void)cmeth;
@end

typedef NewI DeprI __attribute__((deprecated("blah"))); // expected-note 4 {{'DeprI' has been explicitly marked deprecated here}}

@interface SI : DeprI // expected-warning {{'DeprI' is deprecated: blah}}
-(DeprI*)meth; // expected-warning {{'DeprI' is deprecated: blah}}
@end

@implementation SI
-(DeprI*)meth { // expected-warning {{'DeprI' is deprecated: blah}}
  [DeprI cmeth]; // expected-warning {{'DeprI' is deprecated: blah}}
  return 0;
}
@end

// <rdar://problem/15407366> and <rdar://problem/15466783>:
// - Using deprecated class name inside class should not warn about deprecation.
// - Implementations of deprecated classes should not result in deprecation warnings.
__attribute__((deprecated))
@interface DeprecatedClassA
@end

__attribute__((deprecated))
@interface DeprecatedClassB
// The self-reference return value should not be
// flagged as the use of a deprecated declaration.
+ (DeprecatedClassB *)sharedInstance; // no-warning

// Since this class is deprecated, returning a reference
// to another deprecated class is fine as they may
// have been deprecated together.  From a user's
// perspective they are all deprecated.
+ (DeprecatedClassA *)somethingElse; // no-warning
@end

@implementation DeprecatedClassB
+ (DeprecatedClassB *)sharedInstance
{
  // This self-reference should not
  // be flagged as a use of a deprecated
  // declaration.
  static DeprecatedClassB *x; // no-warning
  return x;
}
+ (DeprecatedClassA *)somethingElse {
  // Since this class is deprecated, referencing
  // another deprecated class is also OK.
  static DeprecatedClassA *x; // no-warning
  return x;
}

@end

// rdar://16068470
@interface TestBase
@property (nonatomic, strong) id object __attribute__((deprecated("deprecated"))); // expected-note {{'object' has been explicitly marked deprecated here}} \
expected-note {{property 'object' is declared deprecated here}} \
expected-note {{'setObject:' has been explicitly marked deprecated here}}
@end

@interface TestDerived : TestBase
@property (nonatomic, strong) id object;
@end

@interface TestUse @end

@implementation TestBase @end

@implementation TestDerived @end

@implementation TestUse

- (void) use
{
    TestBase *base = (id)0;
    TestDerived *derived = (id)0;
    id object = (id)0;

    base.object = object; // expected-warning {{'object' is deprecated: deprecated}}
    derived.object = object;

    [base setObject:object];  // expected-warning {{'setObject:' is deprecated: deprecated}}
    [derived setObject:object];
}

@end

