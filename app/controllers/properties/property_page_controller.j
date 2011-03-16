/*
 * This might be the page property controller, however we never communicate directly
 * with the page object, rather via the document view controller (DVC). The DVC 
 * responsible for maintaining the document view in the editor, so it also needs 
 * to know about color changes etc. Therefore it makes sense that the DVC notifies the
 * current page object of any changes.
 *
 * This also has the advantage that if the user decides to change pages, the current 
 * page (that is shown) is modified.
 */
@implementation PropertyPageController : PropertyWindowController
{
  @outlet CPColorWell m_colorWell;

  @outlet CPButton    m_size_a4;
  @outlet CPButton    m_size_letter;

  @outlet CPButton    m_orientation_portrait;
  @outlet CPButton    m_orientation_landscape;
  @outlet CPTextField m_name_field;
  @outlet CPView      m_name_bg_view;
  @outlet CPView      m_size_view;

  Page m_pageObj;

  CPColor m_origColor;
  CPString m_origOrientation;
  CPString m_origPageSize;
}

- (void)awakeFromCib
{
  [super awakeFromCib];
  [CPBox makeBorder:m_colorWell];
  [CPBox makeBorder:m_name_bg_view];
  [CPBox makeBorder:m_size_view];

  m_pageObj = [[PageViewController sharedInstance] currentPage];

  [m_colorWell setColor:[m_pageObj getColor]];
  m_origColor = [m_pageObj getColor];

  if ( [m_pageObj isLandscape] ) {
    [m_orientation_landscape setState:CPOnState];
    m_origOrientation = "landscape";
  } else {
    [m_orientation_portrait setState:CPOnState];
    m_origOrientation = "portrait";
  }

  if ( [m_pageObj isLetter] ) {
    [m_size_letter setState:CPOnState];
    m_origPageSize = "letter";
  } else {
    [m_size_a4 setState:CPOnState];
    m_origPageSize = "a4";
  }
  [m_name_field setStringValue:[m_pageObj name]];
  [_window makeFirstResponder:m_name_field];
}

- (CPAction)updateColor:(id)sender
{
  [[DocumentViewController sharedInstance] setBackgroundColor:[m_colorWell color]];
}

- (CPAction)updateSize:(id)sender
{
  if ( sender == m_size_a4 ) {
    [[DocumentViewController sharedInstance] setPageSize:"a4"];
  } else {
    [[DocumentViewController sharedInstance] setPageSize:"letter"];
  }
}

- (CPAction)updateOrientation:(id)sender
{
  if ( sender == m_orientation_landscape ) {
    [[DocumentViewController sharedInstance] setPageOrientation:"landscape"];
  } else {
    [[DocumentViewController sharedInstance] setPageOrientation:"portrait"];
  }
}

- (CPAction)cancel:(id)sender
{
  [super cancel:sender];
  [[DocumentViewController sharedInstance] setPageSize:m_origPageSize];
  [[DocumentViewController sharedInstance] setPageOrientation:m_origOrientation];
  [[DocumentViewController sharedInstance] setBackgroundColor:m_origColor];
}

- (CPAction)accept:(id)sender
{
  [m_pageObj setName:[m_name_field stringValue]];
  [[PageViewController sharedInstance] updatePageNameForPage:m_pageObj];
  [[DocumentViewController sharedInstance] updateServer];
  [_window close];
}

@end
