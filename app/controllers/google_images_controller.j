/*
 * Created by Gerrit Riessen
 * Copyright 2010-2011, Gerrit Riessen
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
@implementation GoogleImagesController : CPWindowController
{
  @outlet CPCollectionView m_photoView;
  @outlet CPTextField      m_searchTerm;
  @outlet CPImageView      m_spinnerImage;
  @outlet CPScrollView     m_scrollView;
  @outlet CPTextField      m_indexField;

  CPString m_next_photos_page_url;
  CPTimer m_timer;
}

- (void)awakeFromCib
{
  var photoItem = [[CPCollectionViewItem alloc] init];
  [photoItem setView:[[GoogleImagesPhotoCell alloc] 
                       initWithFrame:CGRectMake(0, 0, 150, 150)]];

  [m_photoView setDelegate:self];
  [m_photoView setItemPrototype:photoItem];
  [m_photoView setSelectable:YES];
  [m_photoView setAllowsMultipleSelection:YES];
  [m_photoView setMinItemSize:CGSizeMake(150, 150)];
  [m_photoView setMaxItemSize:CGSizeMake(150, 150)];
  [m_photoView setAutoresizingMask:CPViewWidthSizable];

  [m_spinnerImage setImage:[[PlaceholderManager sharedInstance] spinner]];
  [m_spinnerImage setHidden:YES];

  [m_searchTerm setTarget:self];
  [m_searchTerm setAction:@selector(doSearch:)];
  [m_searchTerm setStringValue:[[[ConfigurationManager sharedInstance] topics] anyValue]];

  [CPBox makeBorder:m_scrollView];

  [self doSearch:self];
  [[CPNotificationCenter defaultCenter] 
    addObserver:self
       selector:@selector(windowWillClose:)
           name:CPWindowWillCloseNotification
         object:_window];
  [_window makeFirstResponder:m_searchTerm];
}

- (void) windowWillClose:(CPNotification)aNotification
{
  // Cleanup
  [[CPNotificationCenter defaultCenter] removeObserver:self];
  [m_timer invalidate];
}

//
// Following are used to monitor the vertical scrollbar and if the users scrolls to
// the bottom, trigger a refresh of the content with page two of the search results.
//
- (void) setupScrollerObserver
{
  // Because there are no notifications that we can listen for to tell us that
  // the scroller (vertical) has reached the bottom, we start a timer and let it
  // check the start of the scroller.
  var scrollerObserver = [[CPInvocation alloc] initWithMethodSignature:nil];
  [scrollerObserver setTarget:self];
  [scrollerObserver setSelector:@selector(checkVerticalScroller:)];
  if ( m_timer ) [m_timer invalidate];
  m_timer = [CPTimer scheduledTimerWithTimeInterval:0.5
                                         invocation:scrollerObserver
                                            repeats:YES];
}

- (void)checkVerticalScroller:(id)obj
{
  // scroller value ranges between 0 and 1, with one being bottom.
  [m_indexField setStringValue:[CPString stringWithFormat:"%d of %d", 
                                         ([[m_scrollView verticalScroller] floatValue] * 
                                          [[m_photoView content] count]),
                                         [[m_photoView content] count]]];

  if ( m_next_photos_page_url && [[m_scrollView verticalScroller] floatValue] == 1 ) {
    [m_timer invalidate];
    [m_spinnerImage setHidden:NO];
    [PMCMWjsonpWorker workerWithUrl:m_next_photos_page_url
                           delegate:self 
                           selector:@selector(loadPhotos:) 
                           callback:"callback"];
  }
}

//
// Button action to retrieve the tweets
//
- (CPAction) doSearch:(id)sender
{
  var userInput = [m_searchTerm stringValue];
    
  if (userInput && userInput !== "") {
    [m_spinnerImage setHidden:NO];
    [m_photoView setContent:[]];
    // TODO remove only data from drag&drop manager
    [PMCMWjsonpWorker workerWithUrl:[GoogleImage searchUrlFor:userInput] 
                           delegate:self 
                           selector:@selector(loadPhotos:) 
                           callback:"callback"];
  }
}

//
// JSONP Request callback
//
- (void)loadPhotos:(JSObject)data
{
  var flickrPhotos = [GoogleImage initWithJSONObjects:data.responseData.results];

  var content = [[m_photoView content] arrayByAddingObjectsFromArray:flickrPhotos];
  [m_photoView setContent:content];
  [[DragDropManager sharedInstance] moreGoogleImages:flickrPhotos];
  [m_photoView setSelectionIndexes:[CPIndexSet indexSet]];
  [m_spinnerImage setHidden:YES];

  // only setup the observer if we got photos back for this request. If not, then there
  // no more pictures to be had for this search term.
  m_next_photos_page_url = [GoogleImage searchUrlNextPage:data.responseData.cursor
                                               searchTerm:[m_searchTerm stringValue]];
  if ( m_next_photos_page_url ) {
    [self setupScrollerObserver];
  } else {
    [m_timer invalidate];
  }
}

//
// The magic of drag and drop
//
- (CPData)collectionView:(CPCollectionView)aCollectionView 
   dataForItemsAtIndexes:(CPIndexSet)indices 
                 forType:(CPString)aType
{
  var idx_store = [];
  [indices getIndexes:idx_store maxCount:([indices count] + 1) inIndexRange:nil];

  var data = [];
  var flickrObjs = [m_photoView content];
  for (var idx = 0; idx < [idx_store count]; idx++) {
    [data addObject:[flickrObjs[idx_store[idx]] id_str]];
  }

  return [CPKeyedArchiver archivedDataWithRootObject:data];
}

- (CPArray)collectionView:(CPCollectionView)aCollectionView 
dragTypesForItemsAtIndexes:(CPIndexSet)indices
{
  return [GoogleImagesDragType];
}

@end
