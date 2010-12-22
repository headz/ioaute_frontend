
@import <Foundation/CPObject.j>

@implementation Tweet : CPObject
{
  CPString fromUser @accessors;
  CPString text     @accessors;
  CPString id_str   @accessors;
  JSObject json     @accessors;
}

- (id)initWithJSONObject:(JSObject)anObject
{
  self = [super init];

  if (self) 
  {
    fromUser = anObject.from_user;
    text     = anObject.text;
    id_str   = anObject.id_str;
    json     = anObject;
  }

  return self;
}

//
// Class method for creating an array of Tweet objects from JSON
//
+ (CPArray)initWithJSONObjects:(CPArray)someJSONObjects
{
  var objects = [[CPArray alloc] init];
    
  for (var idx = 0; idx < someJSONObjects.length; idx++) {
    [objects addObject:[[Tweet alloc] initWithJSONObject:someJSONObjects[idx]]] ;
  }
    
  return objects;
}

@end
