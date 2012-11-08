class Map {
	float W,H;
	ArrayList pivots;
	ArrayList connections;
	Pivot root;
	
	Map() {
		pivots=new ArrayList();
		connections=new ArrayList();
	}
	
	void setRoot(Pivot p) {
		root=p;
	}
	
	void setRoot(double cx, double cy) {
		double dmin=10000;
		for (int i=0;i<pivots.size();i++) {
			Pivot p=(Pivot)pivots.get(i);
			double d=Math.sqrt((p.x-cx)*(p.x-cx)+(p.y-cy)*(p.y-cy));
			if(d<dmin) {
				dmin=d;
				root=p;
			}
		}
	}
	
	Pivot getPivot(String name) {
		Pivot p;
		for (int i=0;i<pivots.size();i++) {
			p=(Pivot)pivots.get(i);
			if (p.id.equals(name)) return p;
		}
		return null;
	}
	
	int indexOfPivot(Pivot p) {
		if (p==null) return -1;
		for (int i=0;i<pivots.size();i++) {
			Pivot pi=(Pivot)pivots.get(i);
			if (p.equals(pi) && p.hidden==pi.hidden) return i;
		}
		return -1;
	}
	
	int indexOfConn(Connection c) {
		for (int i=0;i<connections.size();i++) {
			if (c.equals((Connection)connections.get(i))) return i;
		}
		return -1;
	}
	
	Pivot addPivot(Pivot p) {
		int i=indexOfPivot(p);
		if (i<0) {
			pivots.add(p);
			return p;
		}
		else {
			return ((Pivot)pivots.get(i));
		}		
	}
	
	Pivot addHub(Pivot p) {
		Pivot h=addPivot(p);
		return h;
	}
	
	void linkToHub() {
		ArrayList myHubs=new ArrayList();
		for (int i=0;i<pivots.size();i++) {
			Pivot p=(Pivot)pivots.get(i);
			if(p.hidden) myHubs.add(p);
		}
		for (int i=0;i<pivots.size();i++) {
			Pivot p=(Pivot)pivots.get(i);
			if(p.hidden) continue;
			
			double minD=10000,minD2=10000,minD3=10000;
			Pivot minH=p,minH2=p,minH3=p;
			for (int j=0;j<myHubs.size();j++) {
				Pivot h=(Pivot)myHubs.get(j);
				double d=p.distTo(h);
				if (d<minD) {
					minH3=minH2; minD3=minD2;
					minH2=minH; minD2=minD;
					minH=h;	minD=d;
				}
				else {
				if (d<minD2) {
					minH3=minH2; minD3=minD2;
					minH2=h; minD2=d;
				}
				else if (d<minD3) {
					minH3=h; minD3=d;
				}
			}
			}
			addConnection(minH,p,HUB_CONN_WEIGHT,false,false);
			addConnection(minH2,p,HUB_CONN_WEIGHT,false,false);
//			addConnection(minH3,p,HUB_CONN_WEIGHT,false,false);
		}
	}
	
	Connection addConnection(Pivot p1, Pivot p2, float weight, boolean shown, boolean fixed) {
		p1=addPivot(p1);
		p2=addPivot(p2);
		if (p1.equals(p2)) return null;
		Connection c=new Connection(p1,p2,weight);
		c.hidden=!shown;
		c.fixed=fixed;
		int i=indexOfConn(c);
		if (i<0) {
			connections.add(c);
			return c;
		}
		else {
			return ((Connection)connections.get(i));
		}
	}
	
	Connection addConnection(Pivot p1, Pivot p2,float weight) {
		return addConnection(p1,p2,weight,true,false);
	}
	
	Connection addConnection(Pivot p1, Pivot p2, float weight, double d) {
		Connection c=addConnection(p1,p2,weight, false,true);
		if (c==null) return null;
		c.setLength(d);
		return c;
	}
	
	void update() {	
		for (int i=0;i<connections.size();i++) {
			Connection c=(Connection)connections.get(i);
			c.start.push(c.tension());
			c.end.push(c.tension().scale(-1));
		}
		for (int i=0;i<pivots.size();i++) {
			Pivot p=(Pivot)pivots.get(i);
			p.update();
		}
	}
	
	void print(boolean showConnection, boolean showHidden) {
		
		textAlign(LEFT);
		if(root!=null) {
			stroke(ISO_COLOR);
			strokeWeight(1);
			noFill();
			ellipse((float)root.x,(float)root.y,5,5);
			
			//isochronic circles
			stroke(ISO_COLOR,0.5);
			strokeWeight(1.5/vscale);
			float text_size=TEXT_SIZE/vscale;
			textSize(text_size);
			for (int i=-1;i<6;i++) {
				noFill();
				float r=pow(2,i)*600/TIME_SCALER;
				float step=4/vscale/r;
				for (float k=0;k<TWO_PI;k+=step*2) {
					arc((float)root.x,(float)root.y,r*2,r*2,k,k+step);
				}
				fill(ISO_COLOR);
				rect((float)root.x+r,(float)root.y,text_size*3,-text_size);
				rect((float)root.x-r,(float)root.y,-text_size*3,-text_size);
				fill(1);
				textAlign(LEFT);
				text(int(pow(2,i)*10)+" min",(float)root.x+r,(float)root.y-1);
				textAlign(RIGHT);
				text(int(pow(2,i)*10)+" min",(float)root.x-r,(float)root.y-1);
			}
		}

		if(showConnection) {
			stroke(0.55,1,1);
			strokeWeight(1);
			for (int i=0;i<connections.size();i++) {
				Connection c=(Connection)connections.get(i);
				c.print();
			}
		}
		if(showHidden) {
			noStroke();
			fill(0,1,1);
			for (int i=0;i<pivots.size();i++) {
				Pivot p=(Pivot)pivots.get(i);
				p.print();
			}
		}
	}
}

class Pivot {
	double x,y;
	double x0,y0;
	String id;
	String address;
	Vector velocity=new Vector(0,0);
	Vector acceleration=new Vector(0,0);
	boolean hidden=false;
	boolean fixed=false;
	
	double toX,toY;
	int animationCounter=0;
	
	Pivot(double _x,double _y) {
		x=x0=_x;
		y=y0=_y;
	}
	
	Pivot(double _x,double _y,String _id) {
		x=x0=_x;
		y=y0=_y;
		id=_id;
	}
	
	Pivot(double _x,double _y,String _id,boolean shown) {
		x=x0=_x;
		y=y0=_y;
		id=_id;
		hidden=!shown;
	}
	
	boolean equals(Pivot p) {
		if(id!=null && id.equals(p.id)) return true;
		if(this.distTo(p)<TOLERANCE) return true;
		return false;
	}

	void plus (Vector v) {
		x+=v.x;
		y+=v.y;
	}
	
	void push (Vector f) {
		if(hidden && fixed) acceleration=acceleration.plus(f.scale(1/HUB_WEIGHT));
		else acceleration=acceleration.plus(f.scale(1/WEIGHT));
	}
	
	void update() {
		if (!fixed) {
		velocity=velocity.plus(acceleration);
		if (velocity.abs()>MAX_SPEED) {
			velocity=velocity.norm().scale(MAX_SPEED);
		}
		Vector offset=velocity.scale(TIMESTEP);
		x+=offset.x;
		y+=offset.y;
		velocity=velocity.scale(1-FRICTION);
		acceleration=new Vector(0,0);
		}
		if(fixed && animationCounter>0) {
			x+=(toX-x)/animationCounter;
			y+=(toY-y)/animationCounter;
			animationCounter--;
		}
	}
	
	void print() {
		if(hidden) {
			//float f=(float)distTo(map.root)/MAP_FILE_WIDTH*2;
			//if (f>1) return;
			fill(1);
			float r=(fixed?2:1)/vscale;
			ellipse((float)x,(float)y,r,r);
			fill(0.75,0.5);
			textAlign(LEFT);
			textSize(TEXT_SIZE/vscale);
//			if (address!=null && address.charAt(0)=='#') text(address.substring(1),(float)(x+2),(float)(y-2));
		}
	}
	
	void printName() {
		noStroke();	
		fill(ISO_COLOR);
		float r=6/vscale;
		ellipse((float)x,(float)y,r,r);
		
			String txt="start here";
			
			float text_size=(TEXT_SIZE+1)/vscale;
			textSize(text_size);
			textAlign(LEFT);
			float w=textWidth(txt);
			
			fill(1,0.5);
			noStroke();
			rect((float)x+1,(float)y-1,w+4,-text_size-2);
			fill(ISO_COLOR);
			text(txt,(float)(x+3),(float)(y-3));
	}
		
	double distTo (Pivot that) {
		double dx=that.x-this.x;
		double dy=that.y-this.y;
		return Math.sqrt(dx*dx+dy*dy);
	}
}

class Connection {
	Pivot start,end;
	Vector relation;
	boolean fixed=false;
	boolean hidden=false;
	float weight;
	
	Connection(Pivot p1, Pivot p2,float w) {
		start=p1;
		end=p2;
		relation=new Vector(start,end);
		weight=w;
	}
	
	void setLength(double d) {
		if (d>0) relation=relation.norm().scale(d);
	}
	
	boolean equals(Connection c) {
		if (start.equals(c.start) && end.equals(c.end)) return true;
		if (start.equals(c.end) && end.equals(c.start)) return true;
		return false;
	}
	
	boolean contains(Pivot p) {
			if (p.equals(start) || p.equals(end)) return true;
			return false;
	}
	
	Vector tension() {
		Vector t=(new Vector(start,end)).minus(relation);
		double d=relation.abs();
		if (d==0) d=1;
		double f=t.abs()/d;
		t=t.scale(f*SPRING_CONST);
		if (fixed) {
			t=t.scale(FIX_CONST);
		}
		return t;
	}
	
	void print() {
		if (hidden) return;
		strokeWeight(weight);
		line ((float)start.x,(float)start.y,(float)end.x,(float)end.y);
	}
}

class TimeTable {
	public int slotSize=0;
	HashMap<String,String> table = new HashMap<String,String>();
	ArrayList<String> timeStrings = new ArrayList<String>();
	
	TimeTable() {
	}

	void addTimeString(String name) {
		if (!timeStrings.contains(name)) {
			slotSize++;
			timeStrings.add(name);
		}
	}
	String getTimeString(int _time) {
		if (_time<timeStrings.size()) return timeStrings.get(_time);
		return "";
	}
	
	String get(String _id, int _time) {		
		int slotN=convertTime(_time);
		return table.get(_id+"-"+slotN);
	}
	
	void put(String _id, int _time, String _data) {		
		int slotN=convertTime(_time);
		table.put(_id+"-"+slotN,_data);
	}
	
	int convertTime(int _time) {
		return _time;
	}
}

class Vector {
	double x,y;
	
	Vector() {
		x=0;
		y=0;
	}
	
	Vector(double _x, double _y) {
		x=_x;
		y=_y;
	}
	
	Vector(Pivot start, Pivot end) {
		x=end.x-start.x;
		y=end.y-start.y;
	}
	
	double abs() {
		return Math.sqrt(x*x+y*y);
	}
	
	Vector norm() {
		double l=abs();
		if (l==0) return this;
		return new Vector(x/l,y/l);
	}
	
	Vector plus(Vector that) {
		return new Vector(this.x+that.x,this.y+that.y);
	}
	
	Vector minus(Vector that) {
		return new Vector(this.x-that.x,this.y-that.y);
	}
	
	Vector scale(double s) {
		return new Vector(x*s,y*s);
	}
}

class CSVReader {
	String[] header;
	HashMap item;
	BufferedReader input;

	CSVReader(String path) {
		input=createReader(path);
		try {
			if(input.ready()) {
				String headerLine=input.readLine();
				header=headerLine.split(",");
				item=new HashMap();
				for(int i=0;i<header.length;i++) {
					item.put(header[i],null);
				}
			}	
		}
		catch(IOException e) {	}
	}

	boolean readLine() {
		try {
			if(input!=null && input.ready()) {
				String dataLine=input.readLine();
				if (dataLine==null) return false;
				String[] dataString=dataLine.split(",");
				for(int i=0;i<dataString.length;i++) {
					item.put(header[i],dataString[i]);
				}
				for(int i=dataString.length;i<header.length;i++) {
					item.put(header[i],"");
				}
				return true;
			}
			else {
				input.close();
			}
		}
		catch(IOException e) {	}
		return false;
	}

	boolean hasColumn (String name) {
		return isInArray(name,header);
	}

	ArrayList getHeaders (String[] include, String[] exclude) {
		ArrayList result=new ArrayList();
		for(int i=0;i<header.length;i++) {
			if (exclude==null || !isInArray(header[i],exclude)) {
				if(include==null || isInArray(header[i],include)) {
					result.add(header[i]);
				}
			}
		}
		return result;
	}

	String getString(String key) {
		Object obj=item.get(key);
		if (obj==null) return null;
		return (String)obj;
	}

	int getInt(String key) {
		Object obj=item.get(key);
		if (obj==null) return 0;
		String s=(String)obj;
		return int(s);
	}

	float getFloat(String key) {
		Object obj=item.get(key);
		if (obj==null) return 0;
		String s=(String)obj;
		return float(s);
	}

	boolean isInArray(String s, String[] array) {
		for(int j=0;j<array.length;j++) {
			if (array[j].equals(s)) {
				return true;
			}
		}
		return false;
	}
}