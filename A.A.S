key     Owner;

integer gChannel_num;
integer Listen;

string  URL1 = "secondlife:///app/agent/";
string  URL2 = "/about";

Say(string str)
{
  llOwnerSay(str);
}

list Order_buttons(list buttons) 
{
  return llList2List(buttons, -3, -1) + llList2List(buttons, -6, -4) +
         llList2List(buttons, -9, -7) + llList2List(buttons, -12, -10);
}

list    L_Menu = ["アバター検索","キャンセル"];
integer Menu_Toggle = FALSE;
integer Menu_Timer = 60;

list    Parsedx = [];
string  PartA = "";
string  PartB = "";

integer DetectedAV_num = 0;
integer Menu_Button_num = 6;
integer Menu_Maxnum = 0;
integer Menu_Dialog_Nownum = 0;
integer Type = AGENT;

list    DetectedNames = [];
list    DetectedUUIDs = [];

list    Botton_Number_List = [];
string  Dialog_Text;

list    List_Template = [];

ShowMenu()
{
  Botton_Number_List = [];
  Dialog_Text = "";
   
  integer i;

  for (i = 0; i < (Menu_Button_num) ; i++){
    if (llList2String(DetectedNames,Menu_Dialog_Nownum * Menu_Button_num + i) != ""){
      Botton_Number_List += "No." + (string)(Menu_Dialog_Nownum * Menu_Button_num + i);
      Dialog_Text += "\n" + (string)(Menu_Dialog_Nownum * Menu_Button_num + i) + " " +
      llList2String(DetectedNames,Menu_Dialog_Nownum * Menu_Button_num + i);
    }
  }

  Botton_Number_List += "<---";
  Botton_Number_List += "キャンセル";
  Botton_Number_List += "--->";
  
  llDialog(Owner,
           "メニュー受付時間 " + (string)Menu_Timer + "秒" + "\n" +
           "現在のページ　" + (string)(Menu_Dialog_Nownum + 1) + "/" + (string)(Menu_Maxnum  + 1) + "\n" + 
           Dialog_Text,
           Order_buttons(Botton_Number_List),gChannel_num);
}

Reset1()
{
  llListenRemove(Listen);
  llSetTimerEvent(0);
  llMessageLinked(LINK_SET,301,"",NULL_KEY);
  Menu_Toggle = FALSE;
}

reset2()
{ 
  llListenRemove(Listen);
  llSetTimerEvent(0);
  Menu_Toggle = FALSE;
}

default
{
   
    link_message(integer source, integer num, string str, key id)
    {
      if (num == 300){
        Owner = llGetOwner();
        DetectedNames = [];
        DetectedUUIDs = [];    
        gChannel_num = -1 - (integer)("0x" + llGetSubString((string)llGetOwner(),-7,-1)) + 2000;
        Listen = llListen(gChannel_num,"",Owner,"");
        llDialog(Owner,"\nアバター検索を押すと近くのアバターを検出します" + "\n" + 
                 "次のダイアログで調べたいアバターのボタンを押して下さい"+ "\n" +
                 "メニュー受付時間 " + (string)Menu_Timer + "秒",L_Menu,gChannel_num);
        llSetTimerEvent(Menu_Timer);      
      }
    }
    
    sensor (integer numberDetected)
    {
      DetectedAV_num = numberDetected;
      
      integer i;
      for (i = 0; i < DetectedAV_num ; i++){
        DetectedNames += URL1 + (string)llDetectedKey(i) + URL2; 
        DetectedUUIDs += llDetectedKey(i);
      } 
      Menu_Maxnum = llFloor(DetectedAV_num / Menu_Button_num);
      
      if (DetectedAV_num % Menu_Button_num == 0){
        Menu_Maxnum--;
      }
        Menu_Dialog_Nownum = 0;
        ShowMenu();
        llSetTimerEvent(Menu_Timer);
　　 } 
         
    no_sensor()
    {
      Say("検出範囲内にアバターがいません"); 
      Reset1();
    }
    
    listen(integer channel, string name, key id, string message)
    {
        if (channel == gChannel_num && id == Owner){
        
          Parsedx = llParseString2List(message,["."],[]);
          PartA   = llList2String(Parsedx,0);
          PartB   = llList2String(Parsedx,1);
          
          if (message == "キャンセル"){
            Reset1();
          }
          
          if (message == "アバター検索"){
            llSetTimerEvent(0);  
            llSensor("","",Type,96.0,PI);
          }
 
          if (message == "<---"){
            if (Menu_Dialog_Nownum > 0)
              Menu_Dialog_Nownum--;
            else
              Menu_Dialog_Nownum =  Menu_Maxnum;

            ShowMenu();
          }
          
          if (message == "--->"){
            if (Menu_Dialog_Nownum < Menu_Maxnum)
              Menu_Dialog_Nownum++;
            else
              Menu_Dialog_Nownum = 0;
 
            ShowMenu();
          }
          
          if (PartA == "No"){
            reset2();
            state result;
          }
        }
    }
    
    timer()
    {
      Say("メニュー操作が時間切れになりました");
      Reset1();
    }
}

state result
{
    state_entry()
    {
      Say("\n検索結果を出力します…");
      llSleep(0.1);
      key     AV_UUID = llList2Key(DetectedUUIDs,(integer)PartB);
      list    Attach_UUID_list = llGetAttachedList(AV_UUID);
      list    AttachedNames;
      list    CreatorNames;
      integer a;
      
      while (a < llGetListLength(Attach_UUID_list))
      {
        list temp1 = llGetObjectDetails(llList2Key(Attach_UUID_list,a),[OBJECT_NAME]);
        list temp2 = llGetObjectDetails(llList2Key(Attach_UUID_list,a),[OBJECT_CREATOR]);
        AttachedNames += [llList2String(temp1,0)];
        CreatorNames += [URL1 + llList2String(temp2,0)+ URL2];
        ++a;
      }
      
      string  OrigName = llGetObjectName();
      integer b;
      
      for (b = 0;b < llGetListLength(Attach_UUID_list); b++){
        llSetObjectName("Result " + (string)(b + 1));
        Say("\n" + llList2String(AttachedNames,b) + "\n" + "製作者 " + llList2String(CreatorNames,b));
        llSleep(0.1);
      }
      llSetObjectName(OrigName);
      Say("\n検索結果の出力完了");
      
      llMessageLinked(LINK_SET,301,"",NULL_KEY);
    }
    
    attach(key id)
    {
      if (id == NULL_KEY){
        Reset1();
        llResetScript();
      }
    }
}
