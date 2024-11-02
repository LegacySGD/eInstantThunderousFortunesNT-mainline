<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:x="anything">
	<xsl:namespace-alias stylesheet-prefix="x" result-prefix="xsl" />
	<xsl:output encoding="UTF-8" indent="yes" method="xml" />
	<xsl:include href="../utils.xsl" />

	<xsl:template match="/Paytable">
		<x:stylesheet version="1.0" xmlns:java="http://xml.apache.org/xslt/java" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
			exclude-result-prefixes="java" xmlns:lxslt="http://xml.apache.org/xslt" xmlns:my-ext="ext1" extension-element-prefixes="my-ext">
			<x:import href="HTML-CCFR.xsl" />
			<x:output indent="no" method="xml" omit-xml-declaration="yes" />

			<!-- TEMPLATE Match: -->
			<x:template match="/">
				<x:apply-templates select="*" />
				<x:apply-templates select="/output/root[position()=last()]" mode="last" />
				<br />
			</x:template>

			<!--The component and its script are in the lxslt namespace and define the implementation of the extension. -->
			<lxslt:component prefix="my-ext" functions="formatJson,retrievePrizeTable,getType">
				<lxslt:script lang="javascript">
					<![CDATA[
					var debugFeed = [];
					var debugFlag = false;
					// Format instant win JSON results.
					// @param jsonContext String JSON results to parse and display.
					// @param translation Set of Translations for the game.
					function formatJson(jsonContext, translations, prizeTable, prizeValues, prizeNamesDesc)
					{
						var scenario = getScenario(jsonContext);
						var prizeNames = (prizeNamesDesc.substring(1)).split(',');
						var winLetters = getYourLetters(getOutcomeData(scenario));
						var yourLettersWhole = getYourNumsData(scenario);
						var pipeCount = scenario.split("|").length -1;
						var bonusTriggers = false;
						var bonusGamePlayed = false;
						var bonusGameData = [];
						var yourWins = [];
						var yourNeighbourTriggers = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
						var orderedWins = [];
						if (pipeCount > 1)
						{
							bonusGamePlayed = true;
							bonusGameData = getBonusData(scenario);
						}
						// var regPatt = /\|.*/g;
						var yourLetters = getYourLetters(yourLettersWhole);
						var yourPrizes = getYourLettersInfo(yourLettersWhole, 1);
						var yourNeighbourWins = getYourNeighbourInfo(yourLettersWhole);
						var yourBonusSymbs = getYourLettersInfo(yourLettersWhole, 3);
						var yourTriggerSource = getYourTriggersInfo(yourLettersWhole);
						var convertedPrizeValues = (prizeValues.substring(1)).split('|').map(function(item) {return item.replace(/\t|\r|\n/gm, "")} );

						const gridCols 		= 4;
						const gridRows 		= 4;

						const neighbourIWs    = [-3, 1, 5, 4, 3, -1, -5, -4];
						const symbolWheel 	  = ['F','C','H','D','A','B','G','F','E','H','B','C','A','G','E','C','B','D','F','H','A','D','G','E'];
						const multiplierWheel = [2,1,3,2,1,3,2,1];
						const featureWheel 	  = ['+','.','.','.','.','.','.','.'];

						const symbolsRequired = [7,7,6,6,5,5,4,4];

						const symbPrizes     = 'ABCDEFGHIJKLMNOPQRST';
						const symbInstantWin = '0';
						const symbSpecials   = symbInstantWin;

						// want arrPhases to be an array {phases} of objects: var objPhase = {}
						// assign objPhase.arrGrid = array {cols} of 3-char strings: just arrGrid column data at beginning of phase
						// assign objPhase.arrClusters = array {arrClusters} of objects: var objCluster = {};
						//    assign objPhase.arrClusters.arrCells = array {cells} of integers: the cells of the cluster
						//    assign objPhase.arrClusters.strPrize = string: first non-W cell in cluster
						// assign objPhase.arrBonusCells = array {cells} of integers: the cells that trigger the bonus

						// arrPhases = array {phases} of object {arrGrid: array {cols} of 3-char strings
						//                                       arrClusters: array {phase-clusters} of object {arrCells: array {cluster-cells} of integers
						//                                                                                      strPrize: string
						//                                                                                     }
						//                                       arrBonusCells: array {cells} of integers
						//                                      }

						var arrGridData  = [];

						function getPhasesData(A_arrGridData, A_arrPrizeData)
						{
							var arrBonusCells = [];
							var arrClusters   = [];
							var arrPhases     = [];
							var objPhase      = {};							
							var cellCol       = -1;
							var cellRow       = -1;
							var IWTriggerCount = 0;

							for (var yourWinsIndex = 0; yourWinsIndex < A_arrGridData.length; yourWinsIndex++)
							{
								yourWins[yourWinsIndex] = checkMatch(winLetters, A_arrGridData[yourWinsIndex]);
							}
							for (var yourWinsIndex = 0; yourWinsIndex < yourNeighbourWins.length; yourWinsIndex++)
							{
								if (yourNeighbourWins[yourWinsIndex].length > 0)
								{
									for (var yourNeighbourIndex = 0; yourNeighbourIndex < yourNeighbourWins[yourWinsIndex].length; yourNeighbourIndex++)
									{
										yourWins[yourWinsIndex + neighbourIWs[parseInt(yourNeighbourWins[yourWinsIndex][yourNeighbourIndex] -1)]] = 3;
									}
								}
							}
							for (var yourWinsIndex = 0; yourWinsIndex < A_arrGridData.length; yourWinsIndex++)
							{
								if (yourWins[yourWinsIndex] == 2)
								{
									IWTriggerCount++;
									for (var yourNeighbourIndex = 0; yourNeighbourIndex < yourNeighbourWins[yourWinsIndex].length; yourNeighbourIndex++)
									{
										yourNeighbourTriggers[yourWinsIndex + neighbourIWs[parseInt(yourNeighbourWins[yourWinsIndex][yourNeighbourIndex] -1)]] = IWTriggerCount;
									}
								}
							}
							for (var i = 1; i < 3; i++)
							{
								for (var yourWinsIndex = 0; yourWinsIndex < A_arrGridData.length; yourWinsIndex++)
								{
									if (yourWins[yourWinsIndex] == i)
									{
										orderedWins.push(yourWinsIndex + 1);
										if (i == 2)
										{
											for (var yourTriggeredIndex = 0; yourTriggeredIndex < A_arrGridData.length; yourTriggeredIndex++)
											{
												if (yourTriggerSource[yourTriggeredIndex] == (yourWinsIndex + 1))
													orderedWins.push(yourTriggeredIndex + 1);
											}
										}
									}
								}
							}

							objPhase = {arrGrid: [], arrPrize: [], arrClusters: [], arrBonusCells: []};

							objPhase.arrGrid = A_arrGridData;
							objPhase.arrPrize = A_arrPrizeData;

							arrPhases.push(objPhase);
							return arrPhases;
						}

						var mgPhases = getPhasesData(yourLetters, yourPrizes); 

						var bonusGames  = [];
						const prizeSymbs = 'ABCDEFGH';
						var bGameRunningTotals = prizeSymbs.split("").map(function(item) {return 0;} ).concat(0);
						var bTest = prizeSymbs.split("").map(function(item) {return 0;} ).concat(0);

						if (bonusGamePlayed)
						{
							var bonusMultiplier = 0;
							var bonusNumber = 0;
							var bonusRefNumber = 0;

							for (var bonusIndex = 0; bonusIndex < bonusGameData.length; bonusIndex++)
							{
								bonusMultiplier = multiplierWheel[parseInt(bonusGameData[bonusIndex][1]) -1];
								for (var bonusSpinIndex = 0; bonusSpinIndex < 3; bonusSpinIndex++)
								{
									bonusNumber = (parseInt(bonusGameData[bonusIndex][0]) + bonusSpinIndex);
									bonusRefNumber = (bonusNumber > 24) ? (bonusNumber -25) : (bonusNumber -1);
									bGameRunningTotals[prizeSymbs.indexOf(symbolWheel[bonusRefNumber])] += bonusMultiplier;
								}
								if (featureWheel[parseInt(bonusGameData[bonusIndex][2] - 1)] == '+')
								{
									bGameRunningTotals[8]++;
								}
								bTest = bGameRunningTotals.slice(0);
								bonusGames.push(bTest);
							}
						}

						///////////////////////
						// Output Game Parts //
						///////////////////////

						const smCellSize   = 30;
						const summaryCellSize = 24;
						const cellSizeX    = 72;
						const cellSizeY    = 48;
						const summaryCellTextX = 13;
						const summaryCellTextY = 15;
						const cellMargin   = 1;
						const smCellTextX  = 16;
						const smCellTextY  = 17;
						const cellTextX    = 37; 
						const cellTextY    = 20; 
						const cellTextY2   = 40; 
						const colourBlack  = '#000000'; 
						const colourBlue   = '#63dcff'; 
						const colourGreen  = '#00ff00'; 
						const colourLime   = '#00fea2'; 
						const colourNavy   = '#6496ff'; 
						const colourOrange = '#fdb400'; 
						const colourPink   = '#ebc1ff'; 
						const colourCardBack = '#563caa'; 
						const colourRed    = '#fe3439'; 
						const colourWhite  = '#ffffff';  
						const colourYellow = '#ffff3d'; 

						const prizeColours       	  = [colourYellow, colourOrange, colourBlue, colourRed, colourLime, colourNavy, colourGreen, colourPink];
						const arrCellBackgroundColour = [colourWhite, colourCardBack, colourLime, colourYellow];
						const arrCellTextColour 	  = [colourBlack, colourYellow, colourBlack, colourBlack];
						const arrCellBackgroundDesc   = ['', 'matchesWinningSymbolDesc', 'zeusThunderInstantWinDesc', 'thunderSymbolWinDesc'];

						var r = [];

						var boxColourStr  = '';
						var textColourStr = '';
						var canvasIdStr   = '';
						var elementStr    = '';
						var symbDesc      = '';
						var symbPrize     = '';
						var symbSpecial   = '';

						function showSymb(A_strCanvasId, A_strCanvasElement, A_strBoxColour, A_strTextColour, A_strText)
						{
							var canvasCtxStr = 'canvasContext' + A_strCanvasElement;

							r.push('<canvas id="' + A_strCanvasId + '" width="' + (smCellSize + 2 * cellMargin).toString() + '" height="' + (smCellSize + 2 * cellMargin).toString() + '"></canvas>');
							r.push('<script>');
							r.push('var ' + A_strCanvasElement + ' = document.getElementById("' + A_strCanvasId + '");');
							r.push('var ' + canvasCtxStr + ' = ' + A_strCanvasElement + '.getContext("2d");');
							r.push(canvasCtxStr + '.font = "bold 24px Arial";');
							r.push(canvasCtxStr + '.textAlign = "center";');
							r.push(canvasCtxStr + '.textBaseline = "middle";');
							r.push(canvasCtxStr + '.strokeRect(' + (cellMargin + 0.5).toString() + ', ' + (cellMargin + 0.5).toString() + ', ' + smCellSize.toString() + ', ' + smCellSize.toString() + ');');
							r.push(canvasCtxStr + '.fillStyle = "' + A_strBoxColour + '";');
							r.push(canvasCtxStr + '.fillRect(' + (cellMargin + 1.5).toString() + ', ' + (cellMargin + 1.5).toString() + ', ' + (smCellSize - 2).toString() + ', ' + (smCellSize - 2).toString() + ');');
							r.push(canvasCtxStr + '.fillStyle = "' + A_strTextColour + '";');
							r.push(canvasCtxStr + '.fillText("' + A_strText + '", ' + smCellTextX.toString() + ', ' + smCellTextY.toString() + ');');
							r.push('</script>');
						}

						function showSummarySymb(A_strCanvasId, A_strCanvasElement, A_strBoxColour, A_strTextColour, A_strText)
						{
							var canvasCtxStr = 'canvasContext' + A_strCanvasElement;

							r.push('<canvas id="' + A_strCanvasId + '" width="' + (summaryCellSize + 2 * cellMargin).toString() + '" height="' + (summaryCellSize + 2 * cellMargin).toString() + '"></canvas>');
							r.push('<script>');
							r.push('var ' + A_strCanvasElement + ' = document.getElementById("' + A_strCanvasId + '");');
							r.push('var ' + canvasCtxStr + ' = ' + A_strCanvasElement + '.getContext("2d");');
							r.push(canvasCtxStr + '.font = "bold 14px Arial";');
							r.push(canvasCtxStr + '.textAlign = "center";');
							r.push(canvasCtxStr + '.textBaseline = "middle";');
							r.push(canvasCtxStr + '.strokeRect(' + (cellMargin + 0.5).toString() + ', ' + (cellMargin + 0.5).toString() + ', ' + summaryCellSize.toString() + ', ' + summaryCellSize.toString() + ');');
							r.push(canvasCtxStr + '.fillStyle = "' + A_strBoxColour + '";');
							r.push(canvasCtxStr + '.fillRect(' + (cellMargin + 1.5).toString() + ', ' + (cellMargin + 1.5).toString() + ', ' + (summaryCellSize - 2).toString() + ', ' + (summaryCellSize - 2).toString() + ');');
							r.push(canvasCtxStr + '.fillStyle = "' + A_strTextColour + '";');
							r.push(canvasCtxStr + '.fillText("' + A_strText + '", ' + summaryCellTextX.toString() + ', ' + summaryCellTextY.toString() + ');');
							r.push('</script>');
						}
						///////////////
						// Main Game //
						///////////////

						var doTrigger        = false;
						var gridCanvasHeight = gridRows * cellSizeY + 2 * cellMargin;
						var gridCanvasWidth  = gridCols * cellSizeX + 2 * cellMargin;
						var phaseStr         = '';
						var triggerStr       = '';

						function showGridSymbs(A_strCanvasId, A_strCanvasElement, A_arrGrid, A_arrPrize, A_arrWins)
						{
							var canvasCtxStr = 'canvasContext' + A_strCanvasElement;
							var cellX        = 0;
							var cellY        = 0;
							var prizeCell    = '';
							var prizeStr	 = '';
							var symbCell     = '';
							var symbIndex    = -1;
							var temp		 = '';
							var tempNum		 = -1;
							var IWCount		 = 0;
							var boolIWCell   = false;
							var isIWTriggered = false;

							r.push('<canvas id="' + A_strCanvasId + '" width="' + gridCanvasWidth.toString() + '" height="' + gridCanvasHeight.toString() + '"></canvas>');
							r.push('<script>');
							r.push('var ' + A_strCanvasElement + ' = document.getElementById("' + A_strCanvasId + '");');
							r.push('var ' + canvasCtxStr + ' = ' + A_strCanvasElement + '.getContext("2d");');
							r.push(canvasCtxStr + '.textAlign = "center";');
							r.push(canvasCtxStr + '.textBaseline = "middle";');

							for (var gridRow = 0; gridRow < gridRows; gridRow++)
							{
								for (var gridCol = 0; gridCol < gridCols; gridCol++)
								{
									tempNum = ((gridRow)*gridRows) + gridCol;
									temp = A_arrGrid[tempNum];
									if (temp == '@')
									{
										IWCount++;
										symbCell = IWCount.toString();
										boolIWCell = true;
									}
									else
									{
										symbCell = temp;
										boolIWCell = false;
									}
									prizeCell     = A_arrPrize[tempNum];
									prizeStr      = convertedPrizeValues[getPrizeNameIndex(prizeNames, prizeCell)];
									symbIndex     = symbPrizes.indexOf(symbCell);
									
									boxColourStr  = arrCellBackgroundColour[yourWins[tempNum]]; 
									textColourStr = (boolIWCell) ? colourBlack : arrCellTextColour[yourWins[tempNum]]; 
									cellX         = gridCol * cellSizeX;
									cellY         = gridRow * cellSizeY;
									isIWTriggered = (yourNeighbourTriggers[tempNum] > 0);

									r.push(canvasCtxStr + '.strokeRect(' + (cellX + cellMargin + 0.5).toString() + ', ' + (cellY + cellMargin + 0.5).toString() + ', ' + cellSizeX.toString() + ', ' + cellSizeY.toString() + ');');
									r.push(canvasCtxStr + '.fillStyle = "' + boxColourStr + '";');
									r.push(canvasCtxStr + '.fillRect(' + (cellX + cellMargin + 1.5).toString() + ', ' + (cellY + cellMargin + 1.5).toString() + ', ' + (cellSizeX - 2).toString() + ', ' + (cellSizeY - 2).toString() + ');');
									r.push(canvasCtxStr + '.fillStyle = "' + textColourStr + '";');
									if (isIWTriggered == true)
									{
										r.push(canvasCtxStr + '.font = "bold 12px Arial";');
										r.push(canvasCtxStr + '.fillStyle = "' + colourBlack + '";');
										r.push(canvasCtxStr + '.fillRect(' + (cellX + cellMargin * 2).toString() + ', ' + (cellY + cellMargin * 2).toString() + ', ' + (16).toString() + ', ' + (16).toString() + ');');
										r.push(canvasCtxStr + '.fillStyle = "' + colourWhite + '";');
										r.push(canvasCtxStr + '.fillText("' + yourNeighbourTriggers[tempNum].toString() + '", ' + (cellX + cellMargin + 8).toString() + ', ' + (cellY + cellMargin + 10).toString() + ');');
										r.push(canvasCtxStr + '.fillStyle = "' + textColourStr + '";');
									}
									else if (boolIWCell == true)
									{
										r.push(canvasCtxStr + '.fillStyle = "' + colourBlack + '";');
										r.push(canvasCtxStr + '.fillRect(' + (cellX + cellMargin + 20).toString() + ', ' + (cellY + cellMargin + 3).toString() + ', ' + (cellSizeX - 40).toString() + ', ' + (cellSizeY - 18).toString() + ');');
										r.push(canvasCtxStr + '.fillStyle = "' + colourWhite + '";');
									}
									if (parseInt(yourBonusSymbs[tempNum]) > 0)
									{
										r.push(canvasCtxStr + '.font = "bold 12px Arial";');
										r.push(canvasCtxStr + '.fillStyle = "' + colourBlack + '";');
										r.push(canvasCtxStr + '.fillRect(' + (cellX + cellMargin + cellSizeX - 16).toString() + ', ' + (cellY + cellMargin * 2).toString() + ', ' + (16).toString() + ', ' + (16).toString() + ');');
										r.push(canvasCtxStr + '.fillStyle = "' + colourWhite + '";');
										r.push(canvasCtxStr + '.fillText("' + 'B' + '", ' + (cellX + cellMargin + cellSizeX - 8).toString() + ', ' + (cellY + cellMargin + 10).toString() + ');');
										r.push(canvasCtxStr + '.fillStyle = "' + textColourStr + '";');
									}
									r.push(canvasCtxStr + '.font = "bold 28px Arial";');
									r.push(canvasCtxStr + '.fillText("' + symbCell + '", ' + (cellX + cellTextX).toString() + ', ' + (cellY + cellTextY).toString() + ');');
									r.push(canvasCtxStr + '.fillStyle = "' + textColourStr + '";');
									r.push(canvasCtxStr + '.font = "bold 10px Arial";');
									r.push(canvasCtxStr + '.fillText("' + prizeStr + '", ' + (cellX + cellTextX).toString() + ', ' + (cellY + cellTextY2).toString() + ');');
								}
							}
							r.push('</script>');
						}

						function showBonusGrid(A_canvasIdStr, A_elementStr, A_boxColourStr, A_bonusGame, A_prizeIndex)
						{
							var emptyColourBox   = colourCardBack;									
							var winColourBox     = colourYellow;									
							var canvasCtxStr 	 = 'canvasContext' + A_canvasIdStr;
							const prizeSymbs = 'ADECIHFB';
							const orderedprizeSymbs = 'ABCDEFGH';
							const bonusCellHeight = 30;
							const bonusCellWidth  = 18;
							const bonusGridCanvasHeight = 2 * bonusCellHeight + 10 * cellMargin;
							const bonusGridCanvasWidth  = 7 * (bonusCellWidth + 3) + 10 * cellMargin + 10;

							var bonusPrizeText = 'B' + orderedprizeSymbs[A_prizeIndex]; 
							var cashStr        = convertedPrizeValues[getPrizeNameIndex(prizeNames, bonusPrizeText)];

							prizeStr	       = getTranslationByName(prizeSymbs[A_prizeIndex], translations);

							r.push('<canvas id="' + A_canvasIdStr + '" width="' + (bonusGridCanvasWidth + 2 * cellMargin).toString() + '" height="' + (bonusGridCanvasHeight + 2 * cellMargin).toString() + '"></canvas>');
							r.push('<script>');
							r.push('var ' + A_elementStr + ' = document.getElementById("' + A_canvasIdStr + '");');
							r.push('var ' + canvasCtxStr + ' = ' + A_elementStr + '.getContext("2d");');
							r.push(canvasCtxStr + '.font = "bold 14px Arial";');
							r.push(canvasCtxStr + '.textAlign = "center";');
							r.push(canvasCtxStr + '.textBaseline = "middle";');
							r.push(canvasCtxStr + '.strokeRect(' + (cellMargin + 0.5).toString() + ', ' + (cellMargin + 0.5).toString() + ', ' + bonusGridCanvasWidth.toString() + ', ' + bonusGridCanvasHeight.toString() + ');');
							r.push(canvasCtxStr + '.fillStyle = "' + A_boxColourStr + '";');
							r.push(canvasCtxStr + '.fillRect(' + (cellMargin + 1.5).toString() + ', ' + (cellMargin + 1.5).toString() + ', ' + (bonusGridCanvasWidth - 2).toString() + ', ' + (bonusGridCanvasHeight - 2).toString() + ');');
							r.push(canvasCtxStr + '.fillStyle = "' + colourBlack + '";');
							r.push(canvasCtxStr + '.fillRect(' + (cellMargin + 5.5).toString() + ', ' + (cellMargin + 5.5).toString() + ', ' + (bonusGridCanvasWidth - 10).toString() + ', ' + (bonusGridCanvasHeight - 10).toString() + ');');
							r.push(canvasCtxStr + '.fillStyle = "' + A_boxColourStr + '";');
							r.push(canvasCtxStr + '.fillText("' + prizeStr + '", ' + (bonusGridCanvasWidth / 2 + 1).toString() + ', ' + (14).toString() + ');');
							r.push(canvasCtxStr + '.fillText("' + cashStr + '", ' + (bonusGridCanvasWidth / 2 + 1).toString() + ', ' + (bonusGridCanvasHeight / 2 + 25).toString() + ');');
						
							var baseLeft =  Math.floor((bonusGridCanvasWidth - symbolsRequired[A_prizeIndex] * (bonusCellWidth + 3)) / 2) + 2;
							for (var countWinSymbs = 0; countWinSymbs < symbolsRequired[A_prizeIndex]; countWinSymbs++)
							{
								boxColourStr = (A_bonusGame[A_prizeIndex] > countWinSymbs) ? winColourBox : emptyColourBox;
								r.push(canvasCtxStr + '.fillStyle = "' + boxColourStr + '";');
								r.push(canvasCtxStr + '.fillRect(' + (baseLeft + countWinSymbs * (bonusCellWidth + 3)).toString() + ', 21, ' + bonusCellWidth.toString() + ', ' + bonusCellHeight.toString() + ');');
							}

							r.push('</script>');
						}

						///////////////////////
						// Prize Symbols Key //
						///////////////////////
						r.push('<p>' + getTranslationByName("titleSymbolsKey", translations) + '</p>');

						r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');
						r.push('<tr class="tablehead">');
						for (var loopIndex = 1; loopIndex < 6; loopIndex++)
						{
							r.push('<td>' + getTranslationByName("keySymbol", translations) + '</td>');
							r.push('<td>' + getTranslationByName("keyDescription", translations) + '</td>');
						}
						r.push('</tr>');

						var symbolCounter = 0;
						for (var prizeIndex = 1; prizeIndex < 7; prizeIndex++)
						{
							r.push('<tr class="tablebody">');
							for (var innerPrizeIndex = 1; innerPrizeIndex < 6; innerPrizeIndex++)
							{
								symbolCounter = prizeIndex + ((innerPrizeIndex -1)*6);
								if (symbolCounter < 27)
								{
									symbPrize     = String.fromCharCode(symbolCounter + 64);         //symbolCounter.toString();
									canvasIdStr   = 'cvsKeySymb' + symbPrize;
									elementStr    = 'keyPrizeSymb' + symbPrize;
									boxColourStr  = colourWhite;

									r.push('<td align="center">');

									showSymb(canvasIdStr, elementStr, boxColourStr, colourBlack, symbPrize);

									r.push('</td>');
									r.push('<td>' + getTranslationByName(symbPrize, translations) + '</td>');
								}
							}
							r.push('</tr>');
						}

						r.push('</table>');	
						///////////////////////
						// Prize Colours Key //
						///////////////////////
						r.push('<p>' + getTranslationByName("titleWinningColoursKey", translations).toUpperCase() + '</p>');

						r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');
						r.push('<tr class="tablehead">');
						r.push('<td>' + getTranslationByName("keyColour", translations) + '</td>');
						r.push('<td>' + getTranslationByName("keyDescription", translations) + '</td>');
						r.push('</tr>');

						for (var prizeIndex = 1; prizeIndex < arrCellBackgroundColour.length; prizeIndex++)
						{
							symbPrize    = prizeIndex.toString();
							canvasIdStr  = 'cvsKeySymb' + symbPrize;
							elementStr   = 'keyPrizeSymb' + symbPrize;
							boxColourStr = arrCellBackgroundColour[prizeIndex];

							r.push('<tr class="tablebody">');
							r.push('<td align="center">');

							showSymb(canvasIdStr, elementStr, boxColourStr, colourBlack, "");

							r.push('</td>');
							r.push('<td>' + getTranslationByName(arrCellBackgroundDesc[prizeIndex], translations) + '</td>');
							r.push('</tr>');
						}

						symbPrize    = prizeIndex.toString();
						canvasIdStr  = 'cvsKeySymb' + symbPrize;
						elementStr   = 'keyPrizeSymb' + symbPrize;
						boxColourStr = colourBlack;

						r.push('<tr class="tablebody">');
						r.push('<td align="center">');

						showSymb(canvasIdStr, elementStr, boxColourStr, colourWhite, "B");

						r.push('</td>');
						r.push('<td>' + getTranslationByName("bonusTriggerSymbol", translations) + '</td>');
						r.push('</tr>');

						r.push('</table>');						
						
						r.push('<p>' + getTranslationByName("mainGame", translations).toUpperCase() + '</p>');

						///////////////////
						// Lucky Letters //
						///////////////////
						r.push('<p>' + getTranslationByName("winningSymbols", translations) + '</p>');

						r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');
						r.push('<tr class="tablebody">');
						for (var luckyIndex = 0; luckyIndex < winLetters.length; luckyIndex++)
						{
							symbLetter   = winLetters[luckyIndex];
							canvasIdStr  = 'cvsLuckySymb' + symbLetter;
							elementStr   = 'keyLuckySymb' + symbLetter;
							boxColourStr = prizeColours[7];

							r.push('<td>');
							showSymb(canvasIdStr, elementStr, boxColourStr, colourBlack, symbLetter);
							r.push('</td>');
						}
						r.push('</tr>');
						r.push('</table>');

						var iwCount = 0;
						var triggerCount = 0;
						r.push('<p>' + getTranslationByName("yourSymbols", translations) + '</p>');

						////////////////////
						// Main Game Grid //
						////////////////////
						r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');

						r.push('<tr class="tablebody">');

						canvasIdStr = 'cvsMainGrid0'; 
						elementStr  = 'phaseMainGrid0'; 

						r.push('<td style="padding-right:50px; padding-bottom:10px">');

						showGridSymbs(canvasIdStr, elementStr, yourLetters, yourPrizes, yourWins);

						r.push('</td>');
						r.push('<td>');

						r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');

						for (var gameIndex = 0; gameIndex < orderedWins.length; gameIndex ++)
						{
							temp = yourWins[orderedWins[gameIndex] - 1];
							symbPrize    = orderedWins[gameIndex] - 1;
							canvasIdStr  = 'cvsMainGameSummaryPrize' + temp + symbPrize;
							elementStr   = 'eleMainGameSummarySymb' + temp + symbPrize;
							boxColourStr  = arrCellBackgroundColour[temp];
							textColourStr = arrCellTextColour[temp];
							symbLetter    = yourLetters[orderedWins[gameIndex] - 1];
							prizeAmount	  = ' = ' + convertedPrizeValues[getPrizeNameIndex(prizeNames, yourPrizes[orderedWins[gameIndex] - 1])];
							r.push('<tr>');
							r.push('<td>');
							if (temp == 1)
							{
								showSummarySymb(canvasIdStr, elementStr, boxColourStr, textColourStr, symbLetter);
							}
							else if (temp == 2)
							{
								triggerCount = 0;
								iwCount++;
								showSummarySymb(canvasIdStr, elementStr, boxColourStr, textColourStr, iwCount.toString());
							}
							else if (temp == 3)
							{
								triggerCount++;
								if (triggerCount == 1)
								{
									r.push(getTranslationByName("triggers", translations));
								}
								r.push('</td>');
								r.push('<td>');
								showSummarySymb(canvasIdStr, elementStr, boxColourStr, textColourStr, symbLetter);
							}
							r.push(prizeAmount);
							r.push('</td>');
							r.push('</tr>');
						}
						r.push('</table>');

						r.push('</td>');
						r.push('</tr>');
						r.push('</table>');

						////////////////
						// Bonus Game //
						////////////////
						if (bonusGamePlayed)
						{
							var turnSummary = '';
							r.push('<p>' + getTranslationByName("bonusGame", translations).toUpperCase() + '</p>');

							r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');							
							
							for (var bgSpinIndex = 0; bgSpinIndex < bonusGames.length; bgSpinIndex++)
							{
								var spinStr = getTranslationByName("afterSpin", translations) + ' ' + parseInt(bgSpinIndex + 1);
								if (((bgSpinIndex == 0) && (bonusGames[bgSpinIndex][8] == 1)) || ((bgSpinIndex > 0) && (bonusGames[bgSpinIndex][8] > bonusGames[bgSpinIndex -1][8])))
								{
									spinStr += ' <br> +1 ' + getTranslationByName("spin", translations);
								}

								r.push('<tr class="tablebody">');
								r.push('<td valign="top">' + spinStr + '</td>');
								r.push('<td style="padding-bottom:25px">');
								r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');

								for (var bgRowIndex = 0; bgRowIndex < 4; bgRowIndex++)
								{
									turnSummary = getTranslationByName("turnSummary", translations) + ": ";
									r.push('<tr class="tablebody">');

									for (var bgColIndex = 0; bgColIndex < 2; bgColIndex++)
									{
										bgIndex      = bgRowIndex * 2 + bgColIndex;
										canvasIdStr  = 'cvsBonusGame' + bgSpinIndex.toString() + '_' + bgIndex.toString();
										elementStr   = 'eleBonusGame' + bgSpinIndex.toString() + '_' + bgIndex.toString();
										boxColourStr = prizeColours[bgIndex];
									
										r.push('<td align="center">');

										showBonusGrid(canvasIdStr, elementStr, boxColourStr, bonusGames[bgSpinIndex], bgIndex);		

										r.push('</td>');
										if (bgSpinIndex == 0)
										{
											turnSummary += "+" + bonusGames[bgSpinIndex][bgIndex];
										}
										else
										{
											turnSummary += "+" + (bonusGames[bgSpinIndex][bgIndex] - bonusGames[bgSpinIndex-1][bgIndex]);
										}
										if (bgIndex % 2 == 0) // Even or Odd
										{
											turnSummary += ' : ';
										}
									
										if (bgIndex % 2 > 0) // Even or Odd
										{
											r.push('<td align="left">');
											r.push(turnSummary + '<br>');
											if ((bgSpinIndex > 1) && (bonusGames[bgSpinIndex][bgIndex-1] == symbolsRequired[bgIndex-1]) && (bonusGames[bgSpinIndex][bgIndex-1] > bonusGames[bgSpinIndex -1][bgIndex-1]))
											{
												r.push(getTranslationByName("wins", translations) + ' ' + convertedPrizeValues[getPrizeNameIndex(prizeNames, 'B' + prizeSymbs[bgIndex-1])]);
											}
											if ((bgSpinIndex > 1) && (bonusGames[bgSpinIndex][bgIndex] == symbolsRequired[bgIndex]) && (bonusGames[bgSpinIndex][bgIndex] > bonusGames[bgSpinIndex -1][bgIndex]))
											{
												if ((bgSpinIndex > 1) && (bonusGames[bgSpinIndex][bgIndex-1] == symbolsRequired[bgIndex-1]) && (bonusGames[bgSpinIndex][bgIndex-1] > bonusGames[bgSpinIndex -1][bgIndex-1]))
												{
													r.push(' ');
												}
												r.push(getTranslationByName("wins", translations) + ' ' + convertedPrizeValues[getPrizeNameIndex(prizeNames, 'B' + prizeSymbs[bgIndex])]);
											}
											r.push('</td>');
										}
									}
									r.push('</tr>');
								}

								r.push('</table>');

								r.push('</td>');
								r.push('</tr>');
							}
							r.push('</table>');
						}

						r.push('<p>&nbsp;</p>');

						////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
						// !DEBUG OUTPUT TABLE
						if(debugFlag)
						{
							// DEBUG TABLE
							//////////////////////////////////////
							r.push('<table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed">');
							for(var idx = 0; idx < debugFeed.length; ++idx)
 							{
								if(debugFeed[idx] == "")
									continue;
								r.push('<tr>');
 								r.push('<td class="tablebody">');
								r.push(debugFeed[idx]);
 								r.push('</td>');
	 							r.push('</tr>');
							}
							r.push('</table>');
						}
						return r.join('');
					}
					
					// Input: A list of Price Points and the available Prize Structures for the game as well as the wagered price point
					// Output: A string of the specific prize structure for the wagered price point
					function retrievePrizeTable(pricePoints, prizeStructures, wageredPricePoint)
					{
						var pricePointList = pricePoints.split(",");
						var prizeStructStrings = prizeStructures.split("|");
						
						for(var i = 0; i < pricePoints.length; ++i)
						{
							if(wageredPricePoint == pricePointList[i])
							{
								return prizeStructStrings[i];
							}
						}
						
						return "";
					}

					// Input: Json document string containing 'scenario' at root level.
					// Output: Scenario value.
					function getScenario(jsonContext)
					{
						// Parse json and retrieve scenario string.
						var jsObj = JSON.parse(jsonContext);
						var scenario = jsObj.scenario;

						// Trim null from scenario string.
						scenario = scenario.replace(/\0/g, '');

						return scenario;
					}
					
					function getYourLetters(lettersData)
					{
						var result = '';
						for (i = 0; i < lettersData.length; i++)
						{
							result += String.fromCharCode(parseInt(lettersData[i]) + 64);
						}
						return result;
					}

					function getYourLettersInfo(lettersData, index)
					{
						var result = '';

						for (i = 0; i < lettersData.length; i++)
						{
							result += lettersData[i][index];
						}
						return result;
					}
					
					function getYourNeighbourInfo(lettersData)
					{
						var result = [];
						for (i = 0; i < lettersData.length; i++)
						{	
							if (lettersData[i][2] != '')
							{
								result.push(lettersData[i][2]);
							}
							else
							{
								result.push('-');
							}
						}
						return result;
					}

					function getYourTriggersInfo(lettersData)
					{
						var result = [];
						for (i = 0; i < lettersData.length; i++)
						{	
							result.push(lettersData[i][4]);
						}
						return result;
					}

					function getBonusLetters(allLetters)
					{
						var result = '';
						var temp = allLetters.split("|");

						for (i = 0; i < temp.length; i++)
						{
							if (temp[i][3] != '.')
							{
								result += temp[i][3];
							}
						}

						return result;
					}
						
					// Input: Json document string containing 'amount' at root level.
					// Output: Price Point value.
					function getPricePoint(jsonContext)
					{
						// Parse json and retrieve price point amount
						var jsObj = JSON.parse(jsonContext);
						var pricePoint = jsObj.amount;

						return pricePoint;
					}

					// Input: "19,1,18,25,10|20,K,,0,0:2,H,,0,0:18,Q,,0,0:4,J,,0,0:6,E,,0,9:7,H,,0,0:22,I,,0,0:3,C,,0,0:0,O,38,0,0:15,D,,0,0:11,J,,1,0:17,N,,0,0:26,Q,,0,0:24,N,,0,9:18,J,,0,0:21,F,,0,0|3,5,5:1,2,3:23,1,5:20,2,1:16,5,1:15,2,4:22,7,8:16,2,3"
					// Output: ["5", "21", "17", "6", ...]
					function getOutcomeData(scenario)
					{
						var outcomeData = scenario.split("|")[0];
						var outcomePairs = outcomeData.split(",");
						var result = [];
						for(var i = 0; i < outcomePairs.length; ++i)
						{
							result.push(outcomePairs[i]);
						}
						return result;
					}

					// Input: "19,1,18,25,10|20,K,,0,0:2,H,,0,0:18,Q,,0,0:4,J,,0,0:6,E,,0,9:7,H,,0,0:22,I,,0,0:3,C,,0,0:0,O,38,0,0:15,D,,0,0:11,J,,1,0:17,N,,0,0:26,Q,,0,0:24,N,,0,9:18,J,,0,0:21,F,,0,0|3,5,5:1,2,3:23,1,5:20,2,1:16,5,1:15,2,4:22,7,8:16,2,3"
					// Output: ["5", "21", "17", "6", ...]
					function getYourNumsData(scenario)
					{
						var outcomeData = scenario.split("|")[1];
						return outcomeData.split(":").map(function(item) {return item.split(",");} );
					}

					// Input: "19,1,18,25,10|20,K,,0,0:2,H,,0,0:18,Q,,0,0:4,J,,0,0:6,E,,0,9:7,H,,0,0:22,I,,0,0:3,C,,0,0:0,O,38,0,0:15,D,,0,0:11,J,,1,0:17,N,,0,0:26,Q,,0,0:24,N,,0,9:18,J,,0,0:21,F,,0,0|3,5,5:1,2,3:23,1,5:20,2,1:16,5,1:15,2,4:22,7,8:16,2,3"
					// Output: ["5", "21", "17", "6", ...]
					function getBonusData(scenario)
					{
						var outcomeData = scenario.split("|")[2];
						return outcomeData.split(":").map(function(item) {return item.split(",");} );
					}

					// Input: string of the drawn Letters
					// Output: 1 letter is in the drawn letters, 2 if IW, 0 if no win
					function checkMatch(drawnLetters, letter)
					{						
						if(drawnLetters.indexOf(letter) > -1)
						{
							return 1;
						}
						else if(letter == '@')
						{
							return 2;
						}
						return 0;
					}
					
					// Input: "A,B,C,D,..." and "A"
					// Output: index number
					function getPrizeNameIndex(prizeNames, currPrize)
					{
						for(var i = 0; i < prizeNames.length; ++i)
						{
							if(prizeNames[i] == currPrize)
							{
								return i;
							}
						}
					}

					////////////////////////////////////////////////////////////////////////////////////////
					function registerDebugText(debugText)
					{
						debugFeed.push(debugText);
					}
					/////////////////////////////////////////////////////////////////////////////////////////
					function getTranslationByName(keyName, translationNodeSet)
					{
						var index = 1;
						while(index < translationNodeSet.item(0).getChildNodes().getLength())
						{
							var childNode = translationNodeSet.item(0).getChildNodes().item(index);
							
							if(childNode.name == "phrase" && childNode.getAttribute("key") == keyName)
							{
								//registerDebugText("Child Node: " + childNode.name);
								return childNode.getAttribute("value");
							}
							
							index += 1;
						}
					}

					// Grab Wager Type
					// @param jsonContext String JSON results to parse and display.
					// @param translation Set of Translations for the game.
					function getType(jsonContext, translations)
					{
						// Parse json and retrieve wagerType string.
						var jsObj = JSON.parse(jsonContext);
						var wagerType = jsObj.wagerType;

						return getTranslationByName(wagerType, translations);
					}
					]]>
				</lxslt:script>
			</lxslt:component>

			<x:template match="root" mode="last">
				<table border="0" cellpadding="1" cellspacing="1" width="100%" class="gameDetailsTable">
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWager']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="//ResultData/WagerOutcome[@name='Game.Total']/@amount" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWins']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="//ResultData/PrizeOutcome[@name='Game.Total']/@totalPay" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
				</table>
			</x:template>

			<!-- TEMPLATE Match: digested/game -->
			<x:template match="//Outcome">
				<x:if test="OutcomeDetail/Stage = 'Scenario'">
					<x:call-template name="Scenario.Detail" />
				</x:if>
			</x:template>

			<!-- TEMPLATE Name: Wager.Detail (base game) -->
			<x:template name="Scenario.Detail">
				<x:variable name="odeResponseJson" select="string(//ResultData/JSONOutcome[@name='ODEResponse']/text())" />
				<x:variable name="translations" select="lxslt:nodeset(//translation)" />
				<x:variable name="wageredPricePoint" select="string(//ResultData/WagerOutcome[@name='Game.Total']/@amount)" />
				<x:variable name="prizeTable" select="lxslt:nodeset(//lottery)" />

				<table border="0" cellpadding="0" cellspacing="0" width="100%" class="gameDetailsTable">
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='wagerType']/@value" />
							<x:value-of select="': '" />
							<x:value-of select="my-ext:getType($odeResponseJson, $translations)" disable-output-escaping="yes" />
						</td>
					</tr>
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='transactionId']/@value" />
							<x:value-of select="': '" />
							<x:value-of select="OutcomeDetail/RngTxnId" />
						</td>
					</tr>
				</table>
				<br />			
				
				<x:variable name="convertedPrizeValues">
					<x:apply-templates select="//lottery/prizetable/prize" mode="PrizeValue"/>
				</x:variable>

				<x:variable name="prizeNames">
					<x:apply-templates select="//lottery/prizetable/description" mode="PrizeDescriptions"/>
				</x:variable>


				<x:value-of select="my-ext:formatJson($odeResponseJson, $translations, $prizeTable, string($convertedPrizeValues), string($prizeNames))" disable-output-escaping="yes" />
			</x:template>

			<x:template match="prize" mode="PrizeValue">
					<x:text>|</x:text>
					<x:call-template name="Utils.ApplyConversionByLocale">
						<x:with-param name="multi" select="/output/denom/percredit" />
					<x:with-param name="value" select="text()" />
						<x:with-param name="code" select="/output/denom/currencycode" />
						<x:with-param name="locale" select="//translation/@language" />
					</x:call-template>
			</x:template>

			<x:template match="description" mode="PrizeDescriptions">
				<x:text>,</x:text>
				<x:value-of select="text()" />
			</x:template>
			<x:template match="text()" />
		</x:stylesheet>
	</xsl:template>

	<xsl:template name="TemplatesForResultXSL">
		<x:template match="@aClickCount">
			<clickcount>
				<x:value-of select="." />
			</clickcount>
		</x:template>
		<x:template match="*|@*|text()">
			<x:apply-templates />
		</x:template>
	</xsl:template>
</xsl:stylesheet>
