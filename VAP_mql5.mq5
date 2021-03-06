//+------------------------------------------------------------------+
//|                                                       tester.mq5 |
//|                        Copyright 2017, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window

#include <Controls\Dialog.mqh>
#include <Controls\Button.mqh>
#include <Controls\Scrolls.mqh>
#include <Controls\Rect.mqh>

input int getticks = 900000;

bool ok_minmax=true;
string nomeJanela="VAP - Volume At Price", pnl ="panel", lbl="label", pnlVolC="pnlvolCompra", pnlVolV="pnlvolVenda", lblVol="lblvol",pnlDestaque = "pnlDtq",
 lblDestaque="lblDtq";
color clrClaro=clrLavender, clrEscuro=clrBlack, clrBarraC=clrForestGreen, clrBarraV=clrCrimson, clrValorDestaque=clrKhaki;
double y1=0;
float valores_vap[],comp_vend_vap[][2],pixelBarraVol;
int indice_vetor_valores, maior=0, menor=0;
CAppDialog ExtDialog;
CPanel painel,teste;
CButton botaod1,botaoh1,botao30m,botao15m,botaoClaro,botaoEscuro;
MqlTick arrayTicks[];

//+-----------------------------------------------------------+
//|FUNÇOES DA JANELA                                          |
//+-----------------------------------------------------------+
//+-----------------------------------------------------------+
//|criar a janela                                             |
//+-----------------------------------------------------------+
void criarTela(){
   int width=larguraJanela();
   int height=alturaJanela();
   ExtDialog.Create(0,nomeJanela,0,0.1,0.1,width,height); 
   painel.Create(0,"painel_cima",0.1,0.1,0.1,width,height);
  }
//+-----------------------------------------------------------+
//|sumir e aparecer barra de preço e tempo                    |
//+-----------------------------------------------------------+
void sumirPrecoTempo(const int ok_precotempo=0){
   if(!ChartSetInteger(0,CHART_SHOW_DATE_SCALE,0,ok_precotempo))
     {
      Print("Erro barra tempo: ",GetLastError());
     }
   if(!ChartSetInteger(0,CHART_SHOW_PRICE_SCALE,0,ok_precotempo))
     {
      Print("Erro barra preço: ",GetLastError());
     }
  }
//+-----------------------------------------------------------+
//|minimizar e maximizar a janela                             |
//+-----------------------------------------------------------+
void minimizarMaximizar(const bool ok_minmax=false){
   if(ok_minmax)
     {
      sumirPrecoTempo(1);
        }else{
      sumirPrecoTempo(0);
     }
  }
//+-----------------------------------------------------------+
//alterar tamanho da janela                                   |
//+-----------------------------------------------------------+
void alterarTamanho(int width,int height){
   if(width==NULL && height==NULL)
     {
      width= larguraJanela();
      height=alturaJanela();
     }
   ExtDialog.Size(width,height);
   painel.Size(width,height);
   moverBotao(width);
   mover_horizontal(width);
  }
//+-----------------------------------------------------------+
//largura da janela                                           |
//+-----------------------------------------------------------+
int larguraJanela(){
   int width=ChartGetInteger(0,CHART_WIDTH_IN_PIXELS,0);
   return width;
  }
//+-----------------------------------------------------------+
//altura da janela                                            |
//+-----------------------------------------------------------+
int alturaJanela(){
   int height=ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS,0);
   return height;
  }
//+-----------------------------------------------------------+
//+OUTROS                                                     |
//+-----------------------------------------------------------+
//+-----------------------------------------------------------+
//excluir janela de indicadores                               |
//+-----------------------------------------------------------+
void excluirIndicadores(){
   int total=ChartIndicatorsTotal(0,1);
   for(int i=0;i<total;i++)
     {
      string name=ChartIndicatorName(0,1,i);
      ChartIndicatorDelete(0,1,name);
     }
  }
//+-----------------------------------------------------------+
//Destruir componentes                                        |
//+-----------------------------------------------------------+
void destruirTudo(){
   ExtDialog.Destroy(1);
   painel.Destroy(1);
   botaod1.Destroy(1);
   botaoh1.Destroy(1);
   botao30m.Destroy(1);
   botao15m.Destroy(1);
  }
//+-----------------------------------------------------------+
//Destruir componentes barras e valores                       |
//+-----------------------------------------------------------+ 
void destruirBarraValores(){

   int total;

   //compra venda destaque
   ObjectDelete(0,concaternar(pnlDestaque,"last"));
   ObjectDelete(0,concaternar(lblDestaque,"valorLast"));
   
   //botoes
   ObjectDelete(0,"botao_1d");
   ObjectDelete(0,"botao_1d_label");
   ObjectDelete(0,"botao_3h");
   ObjectDelete(0,"botao_3h_label");
   ObjectDelete(0,"botao_1h");
   ObjectDelete(0,"botao_1h_label");
   ObjectDelete(0,"botao_30m");
   ObjectDelete(0,"botao_30m_label");
   ObjectDelete(0,"botao_15m");
   ObjectDelete(0,"botao_15m_label");
   ObjectDelete(0,"botao_5m");
   ObjectDelete(0,"botao_5m_label");
   ObjectDelete(0,"botao_claro");
   ObjectDelete(0,"botao_claro_label");
   ObjectDelete(0,"botao_escuro");
   ObjectDelete(0,"botao_escuro_label");
   //valores e barras
   total= ArraySize(valores_vap)-indice_vetor_valores;
   if(total>5){
      for(total;total>=indice_vetor_valores;total--){
         ObjectDelete(0,concaternar(pnl,(string)valores_vap[total]));
         ObjectDelete(0,concaternar(lbl,(string)valores_vap[total]));
         ObjectDelete(0,concaternar(pnlVolC,(string)valores_vap[total]));
         ObjectDelete(0,concaternar(pnlVolV,(string)valores_vap[total]));
         ObjectDelete(0,concaternar(lblVol,(string)valores_vap[total]));
      }
   }

}
//+-----------------------------------------------------------+
//Data e hora                                                 |
//+-----------------------------------------------------------+
datetime datahora(){
   //datetime data = TimeCurrent();
   datetime data = TimeTradeServer();
   MqlDateTime data2;
   TimeToStruct(data,data2);
   data2.hour =09;
   data2.min = 01;
   data2.sec = 00;
   data = StructToTime(data2);
   return data;
}
//+-----------------------------------------------------------+
//Concatenar Strings                                          |
//+-----------------------------------------------------------+
string concaternar(string stg1, string stg2){
   StringConcatenate(stg1,stg1,stg2);
   return stg1;
}

//+-----------------------------------------------------------+
//Pegar maior e menor numero do vetor de valores              |
//+-----------------------------------------------------------+
void maiorMenorValores(){
 maior=ArrayMaximum(valores_vap,indice_vetor_valores,WHOLE_ARRAY);
 menor=ArrayMinimum(valores_vap,indice_vetor_valores,WHOLE_ARRAY);
}
//+-----------------------------------------------------------+
//PAINEL                                                      |
//+-----------------------------------------------------------+
//+-----------------------------------------------------------+
//cor painel                                                  |
//+-----------------------------------------------------------+
void corPainel(color clr){
   painel.ColorBackground(clr);
  }
//+-----------------------------------------------------------+
//BOTOES                                                      |
//+-----------------------------------------------------------+
//+-----------------------------------------------------------+
//criando botao                                               |
//+-----------------------------------------------------------+
void criarBotoes(){
   int width=larguraJanela();
   int height=alturaJanela();
   int distancia=width-34;
   int altura=height-30;
   
   criarCelulaPanel("botao_1d",distancia,26,30,24,clrWhiteSmoke);
   criarLabelBotao("botao_1d_label",distancia+6,30,46,24,10,"1D");
 
 
 
   distancia=width-68;
   altura=height-10;
   criarCelulaPanel("botao_3h",distancia,26,30,24,clrWhiteSmoke);
   criarLabelBotao("botao_3h_label",distancia+6,30,46,24,10,"3H");

   distancia=width-102;
   altura=height-10;
   criarCelulaPanel("botao_1h",distancia,26,30,24,clrWhiteSmoke);
   criarLabelBotao("botao_1h_label",distancia+6,30,46,24,10,"1H");

   distancia=width-136;
   altura=height-10;
   criarCelulaPanel("botao_30m",distancia,26,30,24,clrWhiteSmoke);
   criarLabelBotao("botao_30m_label",distancia+2,30,46,24,10,"30M");
   
   distancia=width-168;
   criarCelulaPanel("botao_15m",distancia,26,28,24,clrWhiteSmoke);
   criarLabelBotao("botao_15m_label",distancia+1,30,46,24,10,"15M");

   distancia=width-202;
   criarCelulaPanel("botao_5m",distancia,26,28,24,clrWhiteSmoke);
   criarLabelBotao("botao_5m_label",distancia+5,30,46,24,10,"5M");

   criarCelulaPanel("botao_claro",larguraJanela()-98,52,46,24,clrWhiteSmoke);
   criarLabelBotao("botao_claro_label",larguraJanela()-92,56,46,24,10,"White");
   
   criarCelulaPanel("botao_escuro",larguraJanela()-50,52,46,24,clrWhiteSmoke);
   criarLabelBotao("botao_escuro_label",larguraJanela()-44,56,46,24,10,"Black");

  }
//+-----------------------------------------------------------+
//mover botao                                                 |
//+-----------------------------------------------------------+
void moverBotao(int distancia){

   float x = distancia-34,y = 48;

      ObjectSetInteger(0,"botao_1d",OBJPROP_XDISTANCE,x);
      ObjectSetInteger(0,"botao_1d_label",OBJPROP_XDISTANCE,x+6);
      
      x = distancia-68;
      ObjectSetInteger(0,"botao_3h",OBJPROP_XDISTANCE,x);
      ObjectSetInteger(0,"botao_3h_label",OBJPROP_XDISTANCE,x+6);

      x = distancia-102;
      ObjectSetInteger(0,"botao_1h",OBJPROP_XDISTANCE,x);
      ObjectSetInteger(0,"botao_1h_label",OBJPROP_XDISTANCE,x+6);

      x = distancia-136;
      ObjectSetInteger(0,"botao_30m",OBJPROP_XDISTANCE,x);
      ObjectSetInteger(0,"botao_30m_label",OBJPROP_XDISTANCE,x+2);
      
      x = distancia-168;
      ObjectSetInteger(0,"botao_15m",OBJPROP_XDISTANCE,x);
      ObjectSetInteger(0,"botao_15m_label",OBJPROP_XDISTANCE,x+1);
      
      x = distancia-202;
      ObjectSetInteger(0,"botao_5m",OBJPROP_XDISTANCE,x);
      ObjectSetInteger(0,"botao_5m_label",OBJPROP_XDISTANCE,x+5);
       
      ObjectSetInteger(0,"botao_claro",OBJPROP_XDISTANCE,distancia-98);
      ObjectSetInteger(0,"botao_claro_label",OBJPROP_XDISTANCE,distancia-92);
      
      ObjectSetInteger(0,"botao_escuro",OBJPROP_XDISTANCE,distancia-50);
      ObjectSetInteger(0,"botao_escuro_label",OBJPROP_XDISTANCE,distancia-44);
       

}
//+-----------------------------------------------------------+
//label para botao                                            |
//+-----------------------------------------------------------+
void criarLabelBotao(string nome,int xDistance,int yDistance,int xSize,int ySize, int fontsize, string texto, color cor = clrBlack){
   ObjectCreate(0,nome,OBJ_LABEL,0,0,0);
   
   ObjectSetInteger(0,nome,OBJPROP_XDISTANCE,xDistance);
   ObjectSetInteger(0,nome,OBJPROP_YDISTANCE,yDistance);
   
   ObjectSetInteger(0,nome,OBJPROP_XSIZE,xSize);
   ObjectSetInteger(0,nome,OBJPROP_YSIZE,ySize);
   
   ObjectSetString(0,nome,OBJPROP_TEXT,texto);  
   ObjectSetString(0,nome,OBJPROP_FONT,"Arial");
   ObjectSetInteger(0,nome,OBJPROP_FONTSIZE,fontsize);
   ObjectSetInteger(0,nome,OBJPROP_COLOR,cor);

}
//+-----------------------------------------------------------+
//açao botao claro                                            |
//+-----------------------------------------------------------+
void acaoBotaoClaro(){
   painel.ColorBackground(clrWheat);

}

//+-----------------------------------------------------------+
//açao botao escur                                            |
//+-----------------------------------------------------------+
void acaoBotaoEscuro(){
   painel.ColorBackground(clrBlack);
}

//+-----------------------------------------------------------+
//açao botao 5m                                               |
//+-----------------------------------------------------------+
void acaoBotao5m(){
  destruirBarraValores();
  datetime serv = TimeCurrent();
  MqlDateTime data;
  TimeToStruct(serv,data);
   
   if(data.hour<18 && data.hour>=09){
      if(data.min<=04){
         data.hour+=(-1);
         int min = 5-data.min;
         data.min = 59-min;
      }else{
         data.min+=(-05);
     }
    }else{
       if(data.hour>=00 && data.hour<09){
           data.day-=1;
         }
       data.hour=17;
       data.min=55;
     }

    serv = StructToTime(data);
    pegaTodosTicks(serv);
    if(ArraySize(valores_vap)>=5){
       criarValoresVolumes();
       maiorMenorValores();
      }
    moverBidAsk(0);
    criarBotoes(); 
}

//+-----------------------------------------------------------+
//açao botao 15m                                              |
//+-----------------------------------------------------------+
void acaoBotao15m(){
 destruirBarraValores();
 datetime serv = TimeCurrent();
 MqlDateTime data;
 TimeToStruct(serv,data);
 
 if(data.hour<18 && data.hour>=09){
   if(data.min<=14){
      data.hour+=(-1);
      int min = 15-data.min;
      data.min = 59-min;
   }else{
      data.min+=(-15);
   }
 }else{
    if(data.hour>=00 && data.hour<09){
         data.day-=1;
       }
    data.hour=17;
    data.min=45;
 }
 
 serv = StructToTime(data);
 pegaTodosTicks(serv);
 if(ArraySize(valores_vap)>=5){
    criarValoresVolumes();
    maiorMenorValores();
 }
 moverBidAsk(0);
 criarBotoes();
}

//+-----------------------------------------------------------+
//açao botao 30m                                              |
//+-----------------------------------------------------------+
void acaoBotao30m(){
 destruirBarraValores();
 datetime serv = TimeCurrent();
 MqlDateTime data;
 TimeToStruct(serv,data);
 
 if(data.hour<18 && data.hour>=09){
   if(data.min<=29){
      data.hour+=(-1);
      int min = 29-data.min;
      data.min = 59-min;
   }else{
      data.min+=(-30);
   }
 }else{
    if(data.hour>=00 && data.hour<09){
         data.day-=1;
       }
    data.hour=17;
    data.min=30;

 }
 
 serv = StructToTime(data);
 pegaTodosTicks(serv);
 if(ArraySize(valores_vap)>=5){
    criarValoresVolumes();
    maiorMenorValores();
 }
 moverBidAsk(0);
 criarBotoes();
}

//+-----------------------------------------------------------+
//açao botao 1h                                               |
//+-----------------------------------------------------------+
void acaoBotao1h(){
 destruirBarraValores();
 datetime serv = TimeCurrent();
 MqlDateTime data;
 TimeToStruct(serv,data);
 
 if(data.hour<18 && data.hour>=09){
     data.hour+=(-1);  
 }else{
   if(data.hour>=00 && data.hour<09){
         data.day-=1;
       }
    data.hour=17;
    data.min=00; 
 }
 
 serv = StructToTime(data);
 pegaTodosTicks(serv);
 if(ArraySize(valores_vap)>=5){
    criarValoresVolumes();
    maiorMenorValores();
 }
 moverBidAsk(0);
 criarBotoes();
}

//+-----------------------------------------------------------+
//açao botao 3h                                               |
//+-----------------------------------------------------------+
void acaoBotao3h(){
 destruirBarraValores();
 datetime serv = TimeCurrent();
 MqlDateTime data;
 TimeToStruct(serv,data);
 
 if(data.hour<18 && data.hour>=09){
     data.hour+=(-3);  
 }else{
    if(data.hour>=00 && data.hour<09){
         data.day-=1;
       }
    data.hour=15;
    data.min=00; 
 }
 
 serv = StructToTime(data);
 pegaTodosTicks(serv);
 if(ArraySize(valores_vap)>=5){
    criarValoresVolumes();
    maiorMenorValores();
 }
 moverBidAsk(0);
 criarBotoes();
}

//+-----------------------------------------------------------+
//açao botao 1d                                               |
//+-----------------------------------------------------------+
void acaoBotao1d(){
 destruirBarraValores();
 datetime serv = TimeCurrent();
 MqlDateTime data;
 TimeToStruct(serv,data);
 
 if(data.hour<18 && data.hour>=09){
     data.hour=09;
     data.min=00;  
 }else{
  if(data.hour>=00 && data.hour<09){
         data.day-=1;
       }
    data.hour=09;
    data.min=00;  
 }
 
 serv = StructToTime(data);
 pegaTodosTicks(serv);
 if(ArraySize(valores_vap)>=5){
    criarValoresVolumes();
    maiorMenorValores();
 }
 moverBidAsk(0);
 criarBotoes();
 Print(serv);
}

//+-----------------------------------------------------------+
//CRIANDO TABELA                                              |
//+-----------------------------------------------------------+
//+-----------------------------------------------------------+
//celula                                                      |
//+-----------------------------------------------------------+
void criarCelulaPanel(string nome,int xDistance,int yDistance,int xSize,int ySize, color cor = clrDimGray){
   ObjectCreate(0,nome,OBJ_RECTANGLE_LABEL,0,0,0);
   
   ObjectSetInteger(0,nome,OBJPROP_XDISTANCE,xDistance);
   ObjectSetInteger(0,nome,OBJPROP_YDISTANCE,yDistance);
   
   ObjectSetInteger(0,nome,OBJPROP_XSIZE,xSize);
   ObjectSetInteger(0,nome,OBJPROP_YSIZE,ySize);
   ObjectSetInteger(0,nome,OBJPROP_BORDER_TYPE,BORDER_FLAT);
   ObjectSetInteger(0,nome,OBJPROP_BGCOLOR,cor);

}
//+-----------------------------------------------------------+
//texto celula                                                |
//+-----------------------------------------------------------+
void criarCelulaLabel(string nome,int xDistance,int yDistance,int xSize,int ySize, int fontsize, float valor, color cor = clrWhite, bool indicar=false){
   ObjectCreate(0,nome,OBJ_LABEL,0,0,0);
   
   ObjectSetInteger(0,nome,OBJPROP_XDISTANCE,xDistance);
   ObjectSetInteger(0,nome,OBJPROP_YDISTANCE,yDistance);
   
   ObjectSetInteger(0,nome,OBJPROP_XSIZE,xSize);
   ObjectSetInteger(0,nome,OBJPROP_YSIZE,ySize);
   if(indicar){
      ObjectSetString(0,nome,OBJPROP_TEXT,simplificarK(valor)); 
   }else{
      ObjectSetString(0,nome,OBJPROP_TEXT,(string)NormalizeDouble(valor,2));
   }
    
   
   ObjectSetString(0,nome,OBJPROP_FONT,"Arial");
   ObjectSetInteger(0,nome,OBJPROP_FONTSIZE,fontsize);
   ObjectSetInteger(0,nome,OBJPROP_COLOR,cor);

}
//+-----------------------------------------------------------+
//criar celulas                                               |
//+-----------------------------------------------------------+
void criarCelula(string pnl, string lbl, int label_y,int celula_y, int largura_celula,int largura_label, 
                 int celula_distaciaEsq, int label_distaciaEsq, int celula_altura, int label_altura,int font_size,
                 int parametro, double valor){

   int maxheight = larguraJanela();

   StringConcatenate(pnl,pnl,(string)parametro);
   StringConcatenate(lbl,lbl,(string)parametro);
   
   criarCelulaPanel(pnl, maxheight-largura_celula, celula_y, celula_distaciaEsq, celula_altura);
   criarCelulaLabel(lbl, maxheight-largura_label, label_y, label_distaciaEsq, label_altura,font_size,valor);

}

//+-----------------------------------------------------------+
//mover celula e texto horizontalmente                        |
//+-----------------------------------------------------------+
void mover_horizontal(int distancia){
 // int xPanel = distancia-65;
  int xLabel = distancia-52;

   int i,total;
   i=indice_vetor_valores;
   
   if(ArraySize(valores_vap)>=4){
      total=ArraySize(valores_vap)-i;
      
      for(total;total>=i;total--){
         ObjectSetInteger(0,concaternar(lblVol,(string)valores_vap[total]),OBJPROP_XDISTANCE,xLabel);
       }
   }
   
  }
  
//+-----------------------------------------------------------+
//mover celula e texto verticalmente                          |
//+-----------------------------------------------------------+
void mover_vertical(int n, string pnl, string lbl){

   int i,total;
   if(maior == 0){Print("VARIAVEL MAIOR =0");}
   float valor_maior = valores_vap[maior],pontoy; 
   i=indice_vetor_valores;
   total=ArraySize(valores_vap);
   int eixoy1 = ObjectGetInteger(0,concaternar(pnl,(string)valores_vap[maior]),OBJPROP_YDISTANCE,0);
   
   int eixoyVenda = ObjectGetInteger(0,concaternar(pnlDestaque,(string)"last"),OBJPROP_YDISTANCE,0);
   
   
   double y2 = (n -(y1));

    
   if(y2<50 && y2>-50 ){
      pontoy = (eixoy1+(y2));
      
      for(total;total>=i;total--){
   
         ObjectSetInteger(0,concaternar(pnl,(string)valor_maior),OBJPROP_YDISTANCE,pontoy);
         ObjectSetInteger(0,concaternar(lbl,(string)valor_maior),OBJPROP_YDISTANCE,pontoy+2);
         
         ObjectSetInteger(0,concaternar(lblVol,(string)valor_maior),OBJPROP_YDISTANCE,pontoy);
         ObjectSetInteger(0,concaternar(pnlVolC,(string)valor_maior),OBJPROP_YDISTANCE,pontoy);
         ObjectSetInteger(0,concaternar(pnlVolV,(string)valor_maior),OBJPROP_YDISTANCE,pontoy);
         valor_maior-=0.5;
         pontoy+=20;
      
         }
         ObjectSetInteger(0,concaternar(pnlDestaque,"last"),OBJPROP_YDISTANCE,eixoyVenda+(y2));
         ObjectSetInteger(0,concaternar(lblDestaque,(string)"valorLast"),OBJPROP_YDISTANCE,eixoyVenda+(y2)+2);
         
      }
   
   y1=n;

}
//+------------------------------------------------------------------+
// SEPARANDO VALORES E VOLUMES NA MATRIZ                             |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//carregar ticks na array                                            |
//+------------------------------------------------------------------+
int pegaTodosTicks(datetime data){
   //datetime data = datahora();
   ArrayResize(valores_vap,1);
   
   ArrayFree(arrayTicks);
   int ok = CopyTicks(_Symbol,arrayTicks,COPY_TICKS_ALL,data*1000,getticks);
   
   if(ok == -1){
   Print("Erro ao carregar os ticks.");
      return-1;
   }else{
      if(ArraySize(arrayTicks)>=4){
         Print("Ticks copiados.");
         separarPreco(arrayTicks);
         return 1;
      }else{
         Print("Numero de ticks insuficientes.");  
           return -1;
      }
   
    }
}


//+------------------------------------------------------------------+
//jogar na matriz preço e qtd de preços total que tem                |
//+------------------------------------------------------------------+
void separarPreco(MqlTick &array[]){
   int num_matriz=0;
   int cont_arrayResize = 1;
   int tamanho = ArraySize(array);

  
   for(int i=1;i<tamanho;i++){
   
      if(valores_vap[0] != 1){
      
      int indice = procMatriz(array[i].last,num_matriz);
      
      if(indice != -1){
         valores_vap[indice]= array[i].last;
      }else{
         num_matriz++;
         cont_arrayResize++;
         ArrayResize(valores_vap,cont_arrayResize);
         valores_vap[num_matriz] = array[i].last;
      }      
      indice = -1;
      }else{
           valores_vap[num_matriz] = array[i].last;  
            }
   }   
 ArrayResize(comp_vend_vap,ArraySize(valores_vap)); 
 ArrayInitialize(comp_vend_vap,0); 

}


//+------------------------------------------------------------------+
//jogar na matriz volume                                             |
//+------------------------------------------------------------------+
void separarVol(MqlTick &array[]){
   int i =indice_vetor_valores;
   
    for(i;i<ArraySize(valores_vap);i++){
      
      for(int z=0;z<ArraySize(array);z++){
         if(valores_vap[i] == array[z].last){
            adicionarVol(array[z],i);
         }
      }
      
    }

}
   
//+------------------------------------------------------------------+
//procurar na matriz se valor existe                                 |
//+------------------------------------------------------------------+
int procMatriz(float tick,int tamanho){
   for(int i=indice_vetor_valores;i<=tamanho;i++){
       if(tick == valores_vap[i]){
      return i;
      }
   }
   return -1;
}
//+------------------------------------------------------------------+
//adicionar volume a matriz                                          |
//+------------------------------------------------------------------+
void adicionarVol(MqlTick &tick,int indice){

   if(tick.volume<=300){
  
     if(tick.last == tick.bid){
               comp_vend_vap[indice][0] +=float(tick.volume);
               

       }
     if(tick.last == tick.ask){
               comp_vend_vap[indice][1] +=float(tick.volume);
               
       }
    } 
}

//+------------------------------------------------------------------+
//VAP                                                                |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//criar valores do grafico a direita e volume a esquerda             |
//+------------------------------------------------------------------+

void criarValoresVolumes(){

   int total, i=0, posicao_menor=60;
   float sizeBarraVolC, sizeBarraVolV;
   ArraySort(valores_vap);
   
  
   if(ArraySize(valores_vap)>=6){    
      for(int a=0; a<=5; a++){
       if(valores_vap[a] == 0.0 || valores_vap[a] == NULL ){
          i=a;
        }
      }

      i+=1;
      int res = valores_vap[i] - valores_vap[i+1];
      
      if(res>0.5 && res<(-0.5)){
       i++;
      }
      
      indice_vetor_valores=i;
      total= ArraySize(valores_vap)-i;
      //Print(total);
      separarVol(arrayTicks);
      pixelBarraVol= pixelBarraVol();
      
      for(total;total>=i;total--){
         criarCelulaPanel(concaternar(pnl,(string)valores_vap[total]),3,posicao_menor,60,20);
         criarCelulaLabel(concaternar(lbl,(string)valores_vap[total]),10,posicao_menor+2,60,20,10,valores_vap[total]);
         
         sizeBarraVolC=(comp_vend_vap[total][0]+comp_vend_vap[total][1])/pixelBarraVol;
         sizeBarraVolV=comp_vend_vap[total][1]/pixelBarraVol;
         
         criarCelulaPanel(concaternar(pnlVolC,(string)valores_vap[total]),63,posicao_menor,sizeBarraVolC,20,clrBarraC);
         criarCelulaPanel(concaternar(pnlVolV,(string)valores_vap[total]),63,posicao_menor,sizeBarraVolV,20,clrBarraV);
         criarCelulaLabel(concaternar(lblVol,(string)valores_vap[total]),larguraJanela()-52,posicao_menor+2,60,20,10,(comp_vend_vap[total][0]+comp_vend_vap[total][1]),clrWhite,true);
         posicao_menor+=20;
      }
      
      colorirBidAsk();
   
   }else{Print("Array possui menos de 5 valores.");}

}
//+------------------------------------------------------------------+
//colorir ultimos bid e ask negociados                               |
//+------------------------------------------------------------------+
void colorirBidAsk(){
 int last;  
 MqlTick lasttick;
 SymbolInfoTick(_Symbol,lasttick); 
 

 last = ObjectGetInteger(0,concaternar(pnl,(string)lasttick.last),OBJPROP_YDISTANCE,0);
 criarCelulaPanel(concaternar(pnlDestaque,"last"),3,last,60,20,clrValorDestaque);
 criarCelulaLabel(concaternar(lblDestaque,"valorLast"),10,last+2,60,20,10,lasttick.last,clrBlack);

}

//+------------------------------------------------------------------+
//pegar valor da maior barra                                         |
//+------------------------------------------------------------------+
int pixelBarraVol(){
   float volMaior=0;
   
   volMaior = comp_vend_vap[indice_vetor_valores][0]+comp_vend_vap[indice_vetor_valores][1];
  Print(volMaior);
   for(int i=0;i<(ArraySize(comp_vend_vap)/2); i++){
   
      if(volMaior<(comp_vend_vap[i][0]+comp_vend_vap[i][1])){
         volMaior = comp_vend_vap[i][0]+comp_vend_vap[i][1];
      }
   }
   
   volMaior= volMaior/100;
   return volMaior;
}

//+------------------------------------------------------------------+
//simplificar numero de volumes em K                                 |
//+------------------------------------------------------------------+
string simplificarK(float valor){
   
   if(valor <1000){
      return (string)(int)NormalizeDouble((valor),1);
   }else{
      return concaternar((string)DoubleToString((valor/1000),1),"K"); 
   }

}

//+------------------------------------------------------------------+
// LIVRO DE OFERTAS                                                  |
//+------------------------------------------------------------------+
void livro(){
//https://www.mql5.com/pt/articles/1179

MqlBookInfo priceArray[]; 
   bool getBook=MarketBookGet(_Symbol,priceArray); 
   if(getBook) 
     { 
      int size=ArraySize(priceArray); 
      Print("MarketBookInfo sobre ",Symbol()); 
     } 
   else 
     { 
      Print("Falha ao receber DOM para o símbolo ",Symbol()); 
     }
}

//+------------------------------------------------------------------+
// VERIFICAÇAO DE CADA TICK                                          |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
// verificando o tick se é maior que o normal e adicionar o volume   |
//+------------------------------------------------------------------+
void verificandoTick(MqlTick &tick){

   int eixoy1, tamanho_array;
   float sizeBarraVolC, sizeBarraVolV;
   tamanho_array = ArraySize(valores_vap);
   //pixelBarraVol = pixelBarraVol();
   
   if((tick.last <= valores_vap[maior]) && (tick.last >= valores_vap[menor])){
   
      int indice = procMatriz(tick.last,tamanho_array);
      if(indice != -1){
         adicionarVol(tick,indice);
         sizeBarraVolC=comp_vend_vap[indice][0]+comp_vend_vap[indice][1];
         sizeBarraVolV=comp_vend_vap[indice][1];
         ObjectSetString(0,concaternar(lblVol,(string)valores_vap[indice]),OBJPROP_TEXT,simplificarK(sizeBarraVolC));
         sizeBarraVolC=sizeBarraVolC/pixelBarraVol;
         sizeBarraVolV=sizeBarraVolV/pixelBarraVol;
         ObjectSetInteger(0,concaternar(pnlVolC,(string)valores_vap[indice]),OBJPROP_XSIZE,sizeBarraVolC);
         ObjectSetInteger(0,concaternar(pnlVolV,(string)valores_vap[indice]),OBJPROP_XSIZE,sizeBarraVolV);
      }
   }else{
      if(tick.last > valores_vap[maior]){
      
         eixoy1 = ObjectGetInteger(0,concaternar(pnl,(string)valores_vap[maior]),OBJPROP_YDISTANCE,0);
         
         criarCelulaPanel(concaternar(pnl,(string)tick.last),3,eixoy1-20,60,20);
         criarCelulaLabel(concaternar(lbl,(string)tick.last),10,eixoy1-18,60,20,10,tick.last);
         
         int valores = ArrayResize(valores_vap,tamanho_array+1);
         int volumes = ArrayResize(comp_vend_vap,tamanho_array+1);
         comp_vend_vap[tamanho_array][0]=0;
         comp_vend_vap[tamanho_array][1]=0;
        if(volumes != -1 && valores != -1){
        
            valores_vap[tamanho_array]=tick.last;
            adicionarVol(tick,tamanho_array);
            sizeBarraVolC=comp_vend_vap[tamanho_array][0]+comp_vend_vap[tamanho_array][1];
            sizeBarraVolV = comp_vend_vap[tamanho_array][1];
            sizeBarraVolC=sizeBarraVolC/pixelBarraVol;
            sizeBarraVolV=sizeBarraVolV/pixelBarraVol;
            
            criarCelulaPanel(concaternar(pnlVolC,(string)tick.last),63,eixoy1-20,sizeBarraVolC,20,clrBarraC);
            criarCelulaPanel(concaternar(pnlVolV,(string)tick.last),63,eixoy1-20,sizeBarraVolC,20,clrBarraV);
            criarCelulaLabel(concaternar(lblVol,(string)tick.last),larguraJanela()-52,eixoy1-18,60,20,10,(comp_vend_vap[tamanho_array][0]+comp_vend_vap[tamanho_array][1]),clrWhite,true);
         
            maior = tamanho_array;
         }else{Print("Erro ao aumentar a matriz valume e valores.");}
         
        ObjectDelete(0,concaternar(pnlDestaque,"last"));
        ObjectDelete(0,concaternar(lblDestaque,"valorLast"));
        colorirBidAsk();
      }else{
      
         eixoy1 = ObjectGetInteger(0,concaternar(pnl,(string)valores_vap[menor]),OBJPROP_YDISTANCE,0);
         
         criarCelulaPanel(concaternar(pnl,(string)tick.last),3,eixoy1+20,60,20);
         criarCelulaLabel(concaternar(lbl,(string)tick.last),10,eixoy1+20,60,20,10,tick.last);
       
         int valores = ArrayResize(valores_vap,ArraySize(valores_vap)+1);
         int volumes = ArrayResize(comp_vend_vap,ArraySize(valores_vap)+1);
         comp_vend_vap[tamanho_array][0]=0;
         comp_vend_vap[tamanho_array][1]=0;
         
         if(volumes != -1 && valores != -1){
            
              valores_vap[tamanho_array] = tick.last;
              adicionarVol(tick,tamanho_array);
              sizeBarraVolC=comp_vend_vap[tamanho_array][0]+comp_vend_vap[tamanho_array][1];
              sizeBarraVolV=comp_vend_vap[tamanho_array][1];
              sizeBarraVolC=sizeBarraVolC/pixelBarraVol;
              sizeBarraVolV=sizeBarraVolV/pixelBarraVol;
              
              criarCelulaPanel(concaternar(pnlVolC,(string)tick.last),63,eixoy1+20,sizeBarraVolC,20,clrBarraC);
              criarCelulaPanel(concaternar(pnlVolV,(string)tick.last),63,eixoy1+20,sizeBarraVolV,20,clrBarraV);
              criarCelulaLabel(concaternar(lblVol,(string)tick.last),larguraJanela()-52,eixoy1+18,60,20,10,(comp_vend_vap[tamanho_array][0]+comp_vend_vap[tamanho_array][1]),clrWhite,true);
              
              menor = tamanho_array;
         }else{Print("Erro ao aumentar a matriz volume e valores.");}
      
       ObjectDelete(0,concaternar(pnlDestaque,"last"));
       ObjectDelete(0,concaternar(lblDestaque,"valorLast"));
       colorirBidAsk();
      }
   }
 
}
//+------------------------------------------------------------------+
//mover ultimos bid e ask                                            |
//+------------------------------------------------------------------+
void moverBidAsk(float lasttick){
 int eixoyAsk;  
 
if(lasttick != 0){
    eixoyAsk = ObjectGetInteger(0,concaternar(pnl,(string)lasttick),OBJPROP_YDISTANCE,0);
 }else{
  MqlTick tick;
  SymbolInfoTick(_Symbol,tick);
  eixoyAsk = ObjectGetInteger(0,concaternar(pnl,(string)tick.last),OBJPROP_YDISTANCE,0);
  lasttick = tick.last;  
 }
 ObjectSetInteger(0,concaternar(pnlDestaque,"last"),OBJPROP_YDISTANCE,eixoyAsk);
 ObjectSetInteger(0,concaternar(lblDestaque,"valorLast"),OBJPROP_YDISTANCE,eixoyAsk+2);
 
  //atualizar o valor
 ObjectSetString(0,concaternar(lblDestaque,"valorLast"),OBJPROP_TEXT,(string)lasttick);
 

}
//+------------------------------------------------------------------+
//                                                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   excluirIndicadores();
   sumirPrecoTempo();
   criarTela();
   corPainel(clrEscuro);
   datetime data = datahora();
   if(pegaTodosTicks(data)){
      //Print(data);
      if(ArraySize(valores_vap)>=5){
         criarValoresVolumes();
          maiorMenorValores();
      }
   }
 
   criarBotoes();
   
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---
   MqlTick lasttick;
   SymbolInfoTick(_Symbol,lasttick); 
   if(pixelBarraVol !=0){
      verificandoTick(lasttick);
      moverBidAsk(lasttick.last);
   }
   return(rates_total);
  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
void OnChartEvent(const int id,         // Identificador de evento 
                  const long& lparam,   // Parâmetro de evento de tipo long 
                  const double& dparam, // Parâmetro de evento de tipo double 
                  const string& sparam  // Parâmetro de evento de tipo string 
                  ) 
  {

   int width,height;

   if(id == CHARTEVENT_MOUSE_MOVE)
     {
         
         if(sparam == 1){
        
             mover_vertical(dparam, pnl, lbl);
         }else{y1=0;}   
     }

   if(id==CHARTEVENT_CHART_CHANGE /*|| id==CHARTEVENT_CLICK*/)
     {
     height=alturaJanela();
     
      if(ok_minmax==true)
        {
         alterarTamanho(0,0);
           }else{
         width=larguraJanela();
         alterarTamanho((width/3),height);
        }
     }

    if(id==CHARTEVENT_OBJECT_CLICK )
     {
      
     if(sparam == "botao_claro" || sparam == "botao_claro_label"){
         acaoBotaoClaro();
     }
     
     if(sparam == "botao_escuro" || sparam == "botao_escuro_label"){
         acaoBotaoEscuro();
     }
     
     if(sparam == "botao_5m" || sparam == "botao_5m_label"){
         acaoBotao5m();
     }
     
     if(sparam == "botao_15m" || sparam == "botao_15m_label"){
         acaoBotao15m();
     }
     
     if(sparam == "botao_30m" || sparam == "botao_30m_label"){
         acaoBotao30m();
     }
     
     if(sparam == "botao_1h" || sparam == "botao_1h_label"){
         acaoBotao1h();
     }
     
     if(sparam == "botao_1h" || sparam == "botao_1h_label"){
         acaoBotao1h();
     }
     
     if(sparam == "botao_3h" || sparam == "botao_3h_label"){
         acaoBotao3h();
     }
     
     if(sparam == "botao_1d" || sparam == "botao_1d_label"){
         acaoBotao1d();
     }

     }



  }
  
  void OnBookEvent(const string &symbol){


if(symbol==_Symbol)
     {
MqlBookInfo last_bookArray[];
if(MarketBookGet(_Symbol,last_bookArray)){
int label_y=64;
int celula_y= 60;

     for(int i=0; i<ArraySize(last_bookArray); i++){
         MqlBookInfo curr_info = last_bookArray[i];
         criarCelula(pnl,lbl,label_y,celula_y,64,58,66,66,22,20,10,i,curr_info.price);
           celula_y+=20;
           label_y+=20; 
      }
   }
   }
}


void OnTimer(){

}
//+------------------------------------------------------------------+

