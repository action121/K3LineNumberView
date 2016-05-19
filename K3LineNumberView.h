//
//  K3LineNumberView.h
//  K3 Plugin
//
//  Created by usagimaru on 09/05/10.
//  Copyright 2009 usagimaru.
//
//	行番号を表示

#import <Cocoa/Cocoa.h>


@interface K3LineNumberView : NSRulerView
{
	id _textObj;
	NSMutableArray *_lineNumberInfo;
	NSRange _validRange;
	BOOL _adjY;
	
	NSMutableDictionary *_warningLines;
	NSColor *_standardColor, *_warningColor;
	
	unsigned _lineCount;
	unsigned _selection;
	unsigned _charCount;
}

+ (K3LineNumberView*)rulerView;

/* NSTextView を設定 */
- (void)setText:(id)text;

/* 色設定 */
- (void)setStandardColor:(NSColor*)color; // Default: Text Color
- (NSColor*)standardColor;
- (void)setWarningColor:(NSColor*)color; // Default: Red Color
- (NSColor*)warningColor;

/* 常に最新の値とは限らないので注意 */
- (unsigned)lineCount;
- (unsigned)lineNumberOfSelectedLine;
- (unsigned)charCount;

/* 行番号最小値と最大値。最大値を超えた番号は警告表示になる。必要なければ max を0にする */
- (void)setMinNumber:(unsigned)min maxNumber:(unsigned)max;

/* 警告を設定 */
- (void)setWarningLine:(unsigned)index;
- (void)removeWarningLine:(unsigned)index;
- (void)removeAllWarningLines;

/* 行番号のY座標がずれる場合の暫定処置 */
- (void)adjustYPoint:(BOOL)flag;

@end
