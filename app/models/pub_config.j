/*!
  Wrapper around the publication configuration sent via json from the server.
*/
@implementation PubConfig : CPObject
{
  JSObject _json;

  CPString m_continous @accessors(property=continous);
  CPString m_has_shadow @accessors(property=shadow);

  CPView m_page_bg_view @accessors(property=pubBgView);

  int m_snap_grid_width @accessors(property=snapGridWidth,readonly);
}

- (id)init
{
  self = [super init];
  if ( self ) {
    [PageElementColorSupport addToClassOfObject:self];
    m_continous       = "0";
    m_has_shadow      = "1";
    m_snap_grid_width = "0";
    m_page_bg_view    = nil;
  }
  return self;
}

- (void)setSnapGridWidth:(int)value
{
  m_snap_grid_width = value;
  if ( m_snap_grid_width > 0 ) {
    [DocumentViewCellWithSnapgrid addToClass:DocumentViewCell];
  } else {
    [DocumentViewCellWithoutSnapgrid addToClass:DocumentViewCell];
  }
}

- (BOOL) isContinous
{
  return ([m_continous intValue] == 1);
}

- (BOOL) hasShadow
{
  return ([m_has_shadow intValue] == 1);
}

- (void) setConfig:(JSObject)pubConfig
{
  _json = pubConfig.color;
  [self setColorFromJson];
  m_continous       = pubConfig.continous;
  m_has_shadow      = pubConfig.shadow;
  [self setSnapGridWidth:[pubConfig.snap_grid_width intValue]];

  if ( m_page_bg_view ) [m_page_bg_view setBackgroundColor:[self getColor]];

  var shadowView = [[DocumentViewController sharedInstance] shadowView];
  if ( shadowView ) [shadowView setHidden:![self hasShadow]];
}

- (void)requestCompleted:(JSObject)data
{
  switch ( data.action ) {
  case "publications_update":
    if ( data.status == "ok" ) {
      [self setConfig:data.data];
    }
  }
}

@end