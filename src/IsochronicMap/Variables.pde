/* CONFIGURATIONS */

final int APP_WIDTH = 1024;
final int APP_HEIGHT = 768;

final double TIMESTEP=1/30.0;
final double TOLERANCE=0;
final double SPRING_CONST=0.5;
final double FIX_CONST=250;
final double FRICTION=0.1;
final double MAX_SPEED=100;

final float WEIGHT=1.0;
final float HUB_WEIGHT=2500.0;

final float CONN_WEIGHT=0.5;
final float HUB_CONN_WEIGHT=2.0;

float TEXT_SIZE=11;
color ISO_COLOR=color(0,150,255);

float MOUSE_TOLERANCE=10;

int PLAY_INTERVAL=50;
int PIVOT_ANIMATION=50;
int IDLE_TIME=200;
float TRANS_SPEED=1;
float TIME_SCALER=12;

String TIMETABLES_PATH="timetables";

final String MAP_FILE="map.svg";
final String GEO_FILE="controlpoints.csv";
float MAP_FILE_WIDTH=300;
float MAP_FILE_HEIGHT=139.43;
int NX=36;
int NY=18;
float CELL_WIDTH=MAP_FILE_WIDTH/NX;
float CELL_HEIGHT=MAP_FILE_HEIGHT/NY;

final double LAT_TOP = 1.470785906;
final double LNG_LEFT = 103.6169848;
final double LAT_BOTTOM = 1.235892352;
final double LNG_RIGHT = 104.0858022;

float vscale=APP_WIDTH/MAP_FILE_WIDTH*0.85;
float transX=-MAP_FILE_WIDTH/2;
float transY=-MAP_FILE_HEIGHT/2;
float panX=APP_WIDTH/2+70;
float panY=APP_HEIGHT/2-80;
