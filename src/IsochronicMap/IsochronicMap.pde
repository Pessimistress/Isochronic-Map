/*
	Xiaoji Chen, Senseable City Lab, MIT
	April 2011
*/

import geomerative.*;

boolean isRecording=false;
boolean isPlaying=false;
boolean showGrid=false;
boolean showHubs=false;
int playCountdown;

Map map;
Pivot root;
HashMap hubs;
Pivot[] hubsArray;
TimeTable timeTable;
RShape originalMap,isochronicMap;
ArrayList uiControls;
Pivot mouseOver;
int currentTime;

void setup() {
	size(APP_WIDTH,APP_HEIGHT);
	smooth();
	colorMode(HSB,1);
	ellipseMode(CENTER);
	textAlign(LEFT);

	RG.init(this);
	originalMap=RG.loadShape(MAP_FILE);
	isochronicMap=originalMap;

	hubs=new HashMap();
	map=new Map();
	loadGeoInfo();
	loadMap();
	loadTimeTable();
	
	uiControls=new ArrayList();
	uiControls.add(new Button("reset map",width-40,height-100));
}

void draw() {
	
	background(0);

	if(isPlaying) {
		if (map.root==null) {
			isPlaying=false;
		}
		else {
			playCountdown--;
			if (playCountdown<0) {
				currentTime++;
				if (currentTime >= timeTable.slotSize) currentTime = 0;
				updateHub();
				playCountdown=PLAY_INTERVAL;
			}
		}
	}

	translate(panX,panY);
	scale(vscale);
	translate(transX,transY);

	map.update();
	updateRealMap();
	isochronicMap.draw();	
	map.print(showGrid,showHubs);

	if (mouseOver!=null) mouseOver.printName();

	resetMatrix();
		
	for(int i=0;i<uiControls.size();i++) {
		((UIControl)uiControls.get(i)).draw();
	}
	translate(width/2+90,height-60);
	drawTimeline();
	
}


//start_time start_station dest_station1 travel_time1 ...
void updateHub() {
	playCountdown=PLAY_INTERVAL;
	if (map.root==null) return;
	String input=timeTable.get(map.root.id,currentTime);

	if (input==null) {
		println("No data: point "+map.root.id+" at "+timeTable.getTimeString(currentTime));
		return;
	}

	for(int i=0;i<hubsArray.length;i++) {
		hubsArray[i].animationCounter=PIVOT_ANIMATION;
		hubsArray[i].fixed=false;
	}

	String[] inputs=input.split(" ");
	Pivot root=map.root;
	root.fixed=true;
	root.toX=root.x0;
	root.toY=root.y0;

	for(int i=1;i+1<inputs.length;i+=2) {
		Pivot p=(Pivot)hubs.get(inputs[i]);
		if (p==null || p==root) {
			continue;
		}
		double newD=float(inputs[i+1])/TIME_SCALER;	
		double d=Math.sqrt((p.x0-root.x0)*(p.x0-root.x0)+(p.y0-root.y0)*(p.y0-root.y0));

		p.toX=root.x0+(p.x0-root.x0)/d*newD;
		p.toY=root.y0+(p.y0-root.y0)/d*newD;
		p.fixed=true;
	}
}

void loadMap() {
	map.W=MAP_FILE_WIDTH;
	map.H=MAP_FILE_HEIGHT;
	
	int offset_x=1;
	int offset_y=1;
	println(map.pivots.size()+ " control points");
	for (int i=-offset_x;i<=NX+offset_x+1;i++) {
		for (int j=-offset_y;j<=NY+offset_y+1;j++) {
			Pivot p=new Pivot(i*CELL_WIDTH,j*CELL_HEIGHT,"grid-"+i+"-"+j);
			map.addPivot(p);
			Pivot px=map.getPivot("grid-"+(i-1)+"-"+j);
			Pivot py=map.getPivot("grid-"+i+"-"+(j-1));
			if(px!=null) map.addConnection(px,p,CONN_WEIGHT);
			if(py!=null) map.addConnection(p,py,CONN_WEIGHT);
		}
	}
	println(map.pivots.size()+" grid points");
	map.linkToHub();

}

void loadGeoInfo() {
	CSVReader cr=new CSVReader(GEO_FILE);
	while (cr.readLine()) {		
		String id=cr.getString("id");
		String name=cr.getString("name");
		double x=cr.getFloat("longitude");
		double y=cr.getFloat("latitude");
		if (x<LNG_LEFT) continue;

		x=MAP_FILE_WIDTH*(x-LNG_LEFT)/(LNG_RIGHT-LNG_LEFT);
		y=MAP_FILE_HEIGHT*(y-LAT_TOP)/(LAT_BOTTOM-LAT_TOP);

		Pivot p=new Pivot(x,y,id,false);
		p.fixed=true;
		p.address=name;
		map.addPivot(p);
		hubs.put(id,p);
	}
	hubsArray=new Pivot[hubs.size()];
	Object[] obj=hubs.values().toArray();
	for(int i=0;i<obj.length;i++) {
		hubsArray[i]=(Pivot)obj[i];
	}
}

void resetMap() {
	map.root=null;
	for(int i=0;i<hubsArray.length;i++) {
		Pivot p=hubsArray[i];
		p.toX=p.x0;
		p.toY=p.y0;		
		p.animationCounter=PIVOT_ANIMATION;
		p.fixed=true;
	}

	for (int j=0;j<map.pivots.size();j++) {
		Pivot p=(Pivot)map.pivots.get(j);
		p.x=p.x0;
		p.y=p.y0;
		p.velocity=new Vector(0,0);					
	}
}

void updateRealMap() {
	isochronicMap=new RShape(originalMap);
	for (int i=0;i<isochronicMap.children.length;i++) {
		if (isochronicMap.children[i].paths==null) continue;
		for (int k=0;k<isochronicMap.children[i].paths.length;k++){
			RPoint[] points=isochronicMap.children[i].paths[k].getPoints();
			if(points!=null) {
				for(int j=0;j<points.length;j++) {
					points[j]=mapCoord(points[j]);
				}
				isochronicMap.children[i].paths[k]=new RPath(points);
			}
		}
		
	}
}

RPoint mapCoord(RPoint p) {
	float fx,fy;
	float x1,y1,x2,y2,x3,y3,x4,y4;
	float interx1,intery1,interx2,intery2;
	int i,j;
	Pivot pivot;

	fx=p.x/CELL_WIDTH;
	fy=p.y/CELL_HEIGHT;	
	i=floor(fx);
	j=floor(fy);
	fx-=i;
	fy-=j;

	pivot=map.getPivot("grid-"+i+"-"+j);
	x1=(float)pivot.x;	y1=(float)pivot.y;
	pivot=map.getPivot("grid-"+i+"-"+(j+1));
	x2=(float)pivot.x;	y2=(float)pivot.y;
	pivot=map.getPivot("grid-"+(i+1)+"-"+j);
	x3=(float)pivot.x;	y3=(float)pivot.y;
	pivot=map.getPivot("grid-"+(i+1)+"-"+(j+1));
	x4=(float)pivot.x;	y4=(float)pivot.y;

	interx1=x1+fy*(x2-x1);
	intery1=y1+fy*(y2-y1);
	interx2=x3+fy*(x4-x3);
	intery2=y3+fy*(y4-y3);

	return new RPoint(interx1+(interx2-interx1)*fx, intery1+(intery2-intery1)*fx);
}

void loadTimeTable() {
	BufferedReader input;

	//load files
	java.io.File folder = new java.io.File(dataPath(TIMETABLES_PATH));
	java.io.FilenameFilter csvFilter = new java.io.FilenameFilter() {
  		public boolean accept(java.io.File dir, String name) {
    		return name.toLowerCase().endsWith(".csv");
  		}
	};
	String[] filenames = folder.list(csvFilter);
 
	timeTable=new TimeTable();

	for (int i=0;i<filenames.length;i++) {
		String file=filenames[i];
		timeTable.addTimeString(file.replace(".csv",""));
		try {
			input=createReader(TIMETABLES_PATH + "/" + file);
			while(input.ready()) {
				String strLine=input.readLine();
				int fstBreak=strLine.indexOf(" ");
				if (fstBreak<0) continue;
				String id=(strLine.substring(0,fstBreak));

				timeTable.put(id,i,strLine);
			}
			input.close();
		}
		catch(Exception e) {
			println(e);
		}
	}
	println(timeTable.table.size()+" travel time records");
}

