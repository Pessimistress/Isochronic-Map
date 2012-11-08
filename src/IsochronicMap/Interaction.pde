void mouseMoved() {
	// find mouse over pivot
	float x=(mouseX-panX)/vscale-transX;
	float y=(mouseY-panY)/vscale-transY;

	float dMin=MOUSE_TOLERANCE;
	mouseOver=null;
	for(int i=0;i<hubsArray.length;i++) {
		Pivot p=hubsArray[i];
		float d=dist((float)p.x,(float)p.y,x,y);
		if (d<dMin) {
			dMin=d;
			mouseOver=p;
		}
	}

	// find mouse over control
	for(int i=0;i<uiControls.size();i++) {
		UIControl uic=(UIControl)uiControls.get(i);		
		uic.isMouseOver(mouseX,mouseY);
	}
}

void mouseReleased() {
	
	for(int i=0;i<uiControls.size();i++) {
		UIControl uic=(UIControl)uiControls.get(i);
		
		if (uic.isMouseOver(mouseX,mouseY)) {
			if(uic.name.equals("reset map")) {
				isPlaying=false;
				resetMap();				
				currentTime=0;
			}
		}
	}

	if (mouseOver!=null) {
		map.setRoot(mouseOver);
		isPlaying=true;
		updateHub();
	}
	else {
		isPlaying=false;
		resetMap();
		currentTime=0;
	}
}

void keyPressed() {
	if (key=='g') showGrid=!showGrid;
	else if (key=='h') showHubs=!showHubs;
	else if (key=='s') {
		saveFrame("screenshot-####.png"); 
		println("Screenshot saved");
	}
	else if (key=='r') isRecording=!isRecording;
	else if (key=='~') RG.saveShape("screenshot.svg",isochronicMap);
}

void drawTimeline() {
	float w=400,h=6;
	int n=timeTable.slotSize;
	float _x;
	rectMode(CORNER);

	stroke(1);
	strokeWeight(1);
	line(0,h,w,h);
	for(int i=0;i<=n;i++) {		
		if ((i%7==0 || i%7==6)&&i<n) {
			noStroke();
			fill(0.3);
			rect((float)i/n*w,0,w/n,h);
		}
		stroke(1);
		strokeWeight(1);
		_x=(float)i/n*w;
		line(_x,0,_x,h);
	}
	_x=currentTime/n*w;
	stroke(1);
	strokeWeight(3);
	line(_x,h,_x,h+6);
	fill(1);
	textSize(11);
	textAlign(RIGHT);
	text(timeTable.getTimeString(currentTime),-10,10);
}


class Button extends UIControl {
	PImage icon, icon_active;
	float w,h;
	boolean highlight;
	
	Button(String _name,float _x,float _y) {
		name=_name;
		x=_x;
		y=_y;
		w=h=size;
		value=0;
	}
	
	void draw() {
		noStroke();
		if (!highlight) {
			if(icon!=null) image(icon,x,y);
			else {
				fill(themeColor,0.3);
				rect(x,y,w,h);
			}
		}
		else{
			if(icon_active!=null) image(icon_active,x,y);
			else {
				fill(themeColor);
				rect(x,y,w,h);
			}
		}
		textSize(12);
		fill(1);
		textAlign(RIGHT);
		text(name,x-10,y+h/2+4);
	}
	
	void setIcon(PImage _normal,PImage _active) {
		icon=_normal;
		icon_active=_active;
		w=icon.width;
		h=icon.height;
	}
	
	void setValue(float v) {}
	
	float getValue() {
		return 0;
	}
	
	boolean isMouseOver(float mx, float my) {
		if (mx>=x && mx<=x+w && my>=y && my<=y+h) {
			highlight=true;
		}
		else {
			highlight=false;
		}
		return highlight;
	}
}

abstract class UIControl {
	String name;
	float value;
	float x,y;
	float size=15;
	color themeColor=color(1);
	
	UIControl() {}
	abstract void draw();
	abstract void setValue(float v);
	abstract float getValue();
	abstract boolean isMouseOver(float mx, float my);
}