//
//  K3LineNumberView.m
//  K3 Plugin
//
//  Created by usagimaru on 09/05/10.
//  Copyright 2009 usagimaru.
//

#import "K3RulerView.h"
#import "K3NSDictionaryAddition.h"


@interface K3RulerView (K3RulerViewPrivate)

- (void)_drawNumber:(unsigned)num
			atPoint:(NSPoint)point
	 showCursorMark:(BOOL)markFlag
		 validRange:(NSRange)range;

@end

@implementation K3RulerView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
	{
		_lineNumberInfo = [[NSMutableArray alloc] initWithCapacity:0];
		_validRange = NSMakeRange(0, 0);
		_adjY = NO;
		
		_warningLines = [[NSMutableDictionary alloc] initWithCapacity:0];
		_standardColor = [[NSColor textColor] retain];
		_warningColor = [[NSColor redColor] retain];
    }
    return self;
}
+ (K3RulerView*)rulerView {return [[[K3RulerView alloc] init] autorelease];}
- (void)dealloc
{
	if (_textObj)
	{	
		[[NSNotificationCenter defaultCenter] removeObserver:self
														name:NSTextViewDidChangeSelectionNotification
													  object:_textObj];
		[_textObj release];
	}
	if (_lineNumberInfo) [_lineNumberInfo release];
	[_warningLines release];
	[_standardColor release];
	[_warningColor release];
	
	[super dealloc];
}

#pragma mark -

- (void)_didChange:(NSNotification*)not {[self setNeedsDisplay:YES]; /*[self display];*/}

- (void)_calcPoint
{
	NSTextView *textView = (NSTextView*)[[self scrollView] documentView];
	NSLayoutManager *layout = [textView layoutManager];
	NSArray *lines = [[textView string] componentsSeparatedByString:@"\n"];
	
	unsigned cursorPoint = [textView selectedRange].location;	// キャレットの位置
	NSString *toCursor = [[textView string] substringWithRange:NSMakeRange(0, cursorPoint)];
	NSArray *linesOfToCursor = [toCursor componentsSeparatedByString:@"\n"];
	
	unsigned charCount = [layout numberOfGlyphs];				// 文字数
	unsigned i, lineCount = 0, lineCountToCursor = 0;			// 行数
	unsigned glyphCount = 0;									// 行の先頭グリフ番号
	NSPoint scrollPoint = [[[self scrollView] contentView] bounds].origin;
	
	if (_adjY) // なぜかこの数値分（上のルーラー高？）ずれている
		scrollPoint.y -= 54;
	
	if (lines) lineCount = [lines count];
	if (linesOfToCursor) lineCountToCursor = [linesOfToCursor count];
	
	[_lineNumberInfo removeAllObjects];
	for (i=0; i<lineCount; i++)
	{
		NSString *line = [lines objectAtIndex:i];
		NSRect lineRect = [layout extraLineFragmentUsedRect];	// 空行の矩形
		//NSPoint glyphPoint = [layout locationForGlyphAtIndex:glyphCount];
		
		// 最終行でなければ改行分を足す
		if (i < lineCount-1) line = [line stringByAppendingString:@"\n"];
		
		// 空行でなければ行の矩形を取得
		if ([line length] != 0) lineRect = [layout lineFragmentUsedRectForGlyphAtIndex:glyphCount
																		effectiveRange:NULL];
		
		// 行番号の描画座標
		NSPoint linePoint = NSMakePoint(3, 
										NSMinY(lineRect) +NSHeight(lineRect)/2.0 -scrollPoint.y);
		
		glyphCount += [line length];
		
		NSMutableDictionary *info = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									 NSStringFromPoint(linePoint),@"linePoint",nil];
		
		if (i+1 == lineCountToCursor)
		{
			[info setObject:NSStringFromPoint(NSMakePoint(cursorPoint, i)) forKey:@"cursorPoint"];
		}
		[_lineNumberInfo addObject:info];
	}
	
	_lineCount = lineCount;
	_selection = lineCountToCursor;
	_charCount = charCount;
}

- (void)setText:(id)text
{
	if (text)
	{
		if (_textObj)
		{
			[[NSNotificationCenter defaultCenter] removeObserver:self
															name:NSTextViewDidChangeSelectionNotification
														  object:_textObj];
			
			[_textObj release];
		}
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(_didChange:)
													 name:NSTextViewDidChangeSelectionNotification
												   object:text];
		_textObj = [text retain];
	}
}

/* 色設定 */
- (void)setStandardColor:(NSColor*)color
{
	if (color)
	{
		if (_standardColor) [_standardColor release];
		_standardColor = [color retain];
		[self setNeedsDisplay:YES];
	}
}
- (NSColor*)standardColor {return _standardColor;}
- (void)setWarningColor:(NSColor*)color
{
	if (color)
	{
		if (_warningColor) [_warningColor release];
		_warningColor = [color retain];
		[self setNeedsDisplay:YES];
	}
}
- (NSColor*)warningColor {return _warningColor;}

- (unsigned)lineCount {return _lineCount;}
- (unsigned)lineNumberOfSelectedLine {return _selection;}
- (unsigned)charCount {return _charCount;}

- (void)setMinNumber:(unsigned)min maxNumber:(unsigned)max {_validRange = NSMakeRange(min, max);}

/* 警告を設定 */
- (NSString*)_warningKey:(unsigned)integer {return  [NSString stringWithFormat:@"%d",integer];}
- (void)setWarningLine:(unsigned)index
{
	if (index != NSNotFound) [_warningLines setBoolValue:YES forKey:[self _warningKey:index]];
	[self setNeedsDisplay:YES];
}
- (void)removeWarningLine:(unsigned)index
{
	if (index != NSNotFound) [_warningLines removeObjectForKey:[self _warningKey:index]];
	[self setNeedsDisplay:YES];
}
- (void)removeAllWarningLines {[_warningLines removeAllObjects]; [self setNeedsDisplay:YES];}

- (BOOL)_isWarningLineSet:(unsigned)index
{
	if ([_warningLines objectForKey:[self _warningKey:index]])
		return YES;
	return NO;
}

// 行番号のY座標がずれる場合の暫定処置
- (void)adjustYPoint:(BOOL)flag {_adjY = YES; [self setNeedsDisplay:YES];}

/* 行番号を描画 */
- (void)_drawNumber:(unsigned)num
			atPoint:(NSPoint)point
	 showCursorMark:(BOOL)markFlag
		 validRange:(NSRange)range
		  drawnRect:(NSRect)rect
{
	NSString *numStr = [NSString stringWithFormat:@"%02d", num];
	NSMutableDictionary *att = [NSMutableDictionary dictionaryWithCapacity:0];
	
	NSFont *font = [NSFont messageFontOfSize:9];
	NSRect fontRect = [font boundingRectForFont]; // このフォントのピクセルでのサイズ
	float pxlWidth = NSWidth(fontRect) + NSMinX(fontRect);
	float pxlHeight = NSHeight(fontRect) + NSMinY(fontRect);
	NSPoint numberPoint = NSMakePoint(point.x/* +pxlWidth*/, point.y -pxlHeight/2.0);
	
	/* 文字の属性を設定 */
	[att setObject:font forKey:NSFontAttributeName];
	if (num >= range.location && num <= range.length)
		[att setObject:_standardColor forKey:NSForegroundColorAttributeName];
	else if (range.length == 0)
		[att setObject:_standardColor forKey:NSForegroundColorAttributeName];
	else [att setObject:_warningColor forKey:NSForegroundColorAttributeName];
	
	// 警告行が設定されていたら警告色を設定
	if ([self _isWarningLineSet:num])
	{
		[att setObject:_warningColor forKey:NSForegroundColorAttributeName];
	}
	
	/* 描画される矩形内にある場合は描画 */
	NSRect drawnRect;
	drawnRect.origin = numberPoint;
	drawnRect.size = [numStr sizeWithAttributes:att];
	if (NSIntersectsRect(drawnRect, rect))
	{
		[numStr drawAtPoint:numberPoint withAttributes:att];
	}
	
	/* キャレット位置 */
	if (markFlag)
	{
		NSString *caretMark = [NSString stringWithString:@">"];
		
		[caretMark drawAtPoint:NSMakePoint(NSWidth([self bounds]) -pxlWidth +5,
										   point.y -pxlHeight/2.0) withAttributes:att];
	}
}

- (void)drawRect:(NSRect)rect
{
    NSGraphicsContext *nsctx = [NSGraphicsContext currentContext];
	[nsctx saveGraphicsState];
	
	[[NSColor controlHighlightColor] set];
	[NSBezierPath fillRect:rect];
	
    [nsctx setShouldAntialias:NO];
	[[NSColor controlShadowColor] set];
	
    CGContextRef context = (CGContextRef)[nsctx graphicsPort];
    CGContextBeginPath(context);
	CGContextMoveToPoint(context,NSWidth(rect)-1, 0);
	CGContextAddLineToPoint(context,NSWidth(rect)-1,NSHeight([self frame]));
	CGContextStrokePath(context);
	
	[nsctx restoreGraphicsState];
	
	/* 行番号の描画座標を計算 */
	[self _calcPoint];
	
	/* 行番号を描画 */
	unsigned i, n = [_lineNumberInfo count];
	for (i=0; i<n; i++)
	{
		NSDictionary *info = [_lineNumberInfo objectAtIndex:i];
		NSPoint point = NSPointFromString([info objectForKey:@"linePoint"]);
		
		BOOL cursorFlag = NO;
		if ([info objectForKey:@"cursorPoint"]) cursorFlag = YES;
		
		[self _drawNumber:i+1
				  atPoint:point
		   showCursorMark:cursorFlag
			   validRange:_validRange
				drawnRect:rect];
	}
}

@end
