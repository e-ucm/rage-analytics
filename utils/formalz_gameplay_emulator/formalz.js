var TrackerAsset = require('xapi-tracker');
var tracker = new TrackerAsset();


tracker.settings.host = 'http://localhost:3000/';
tracker.settings.trackingCode = '5ec6df7b3d9fcb0076046a2ex7x4ubjly8';
tracker.settings.batch_size = 1000;
//tracker.settings.userToken = 'Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJfaWQiOiI1Y2JmMjkwNmI5MWQyNzAwNDYzMzU3YjkiLCJyYW5kTnVtIjoiMWM5ZWY5OTA3ZWFkMmQ4MWZlMGYiLCJpYXQiOjE1NTYwMzIwMTgsImV4cCI6MTU1NjYzNjgxOH0.iU0lXMlJCYBj7tfjH7pcItLb6dNCIEm5ZpwnGjGzG0s';
tracker.debug = true;

var gameState = {
	money: 100,
	towers: 0,
	lives: 20
}

var sendGameTraces = function(callback){
	var time = 0;
	gameState = {
		money: 100,
		towers: 0,
		lives: 20
	}
	sendGameStart();

	tries = getRandomInt(4, 8)
	var previous_time = 0;
	for (var i = 0; i < tries; i++) {
		console.log('---------- Oleada ' + i + ' ----------');
		time += getRandomInt(30, 120);
		var current_time = time - previous_time;

		var distance = ((tries-1)-i) / (tries-1);

		tracker.setVar('time', time);
		var prewritingtime =  getRandomInt(10, Math.floor(current_time * 0.3));
		tracker.setVar('writing_time',prewritingtime);
		sendChosen('pre', modifyNumber(distance, 0.2));

		tracker.setVar('time', time);
		var postwritingtime =  getRandomInt(10, Math.floor(current_time * 0.3));
		tracker.setVar('writing_time', postwritingtime);
		sendChosen('post', modifyNumber(distance, 0.2));

		var possibletowers = getRandomInt(0, (gameState.money / 20));
		for (var j = 0; j < possibletowers; j++) {
			addTower();
		}

		doWave(time, current_time - prewritingtime - postwritingtime - 10, distance);

		sendGameProgress(i / (tries - 1));
		previous_time = time;
	}

	sendGameEnd();
};

var modifyNumber = function(number, quantity){
	if(number == 0)
		return number;
	
	return getRandomInt(Math.max(number - quantity, 0)*100, Math.min(number + quantity, 1)*100) / 100;
}

var doWave = function(time, duration, distance){
	sendWaveStart();

	var difficulty = 5;

	for (var i = 0; i < 5; i++) {
		tracker.setVar('time', time + ((duration/5) * i));

		if(gameState.lives == 1 || getRandomInt(0,Math.min(difficulty,gameState.towers)) > difficulty/3){
			sendEnemyKilled(i/5);
			continue;
		}
		sendLiveLost(i/5);
	}

	sendWaveEnd(distance);
}

var sendGameStart = function(){
	appendGameState();
	console.log(tracker.Completable.Initialized("level1", tracker.Completable.CompletableType.Level).ToCsv());
}

var sendGameProgress = function(progress){
	appendGameState();
	console.log(tracker.Completable.Progressed("level1", tracker.Completable.CompletableType.Level, progress).ToCsv());
}

var sendGameEnd = function(distance){
	appendGameState();
	console.log(tracker.Completable.Completed("level1", tracker.Completable.CompletableType.Level, true, 1).ToCsv());
}

var sendWaveStart = function(){
	appendGameState();
	console.log(tracker.Completable.Initialized("wave", tracker.Completable.CompletableType.Stage).ToCsv());
}

var sendWaveEnd = function(distance){
	appendGameState();
	console.log(tracker.Completable.Completed("wave", tracker.Completable.CompletableType.Stage, distance == 1).ToCsv());
}

var sendEnemyKilled = function(progress){
	gameState.money+=10;

	appendGameState();
	console.log(tracker.Completable.Progressed("wave", tracker.Completable.CompletableType.Stage, progress).ToCsv());
}

var sendLiveLost = function(progress){
	gameState.lives--;

	appendGameState();
	console.log(tracker.Completable.Progressed("wave", tracker.Completable.CompletableType.Level, progress).ToCsv());
}

var appendGameState = function(){
	tracker.setVar('money', gameState.money);
	tracker.setVar('towers', gameState.towers);
	tracker.setVar('lives', gameState.lives);
}

var addTower = function(){
	if(gameState.money > 20){
		gameState.money -= 20;
		gameState.towers++;
	}
}

var sendChosen = function(type, distance){
	tracker.setSuccess(distance == 0);
	tracker.setScore(distance);

	let complexity = 3 - Math.ceil(distance * 3);
	console.log(tracker.Alternative.Selected(type, getRandomAssert(complexity), tracker.Alternative.AlternativeType.Question).ToCsv());
}

function getRandomInt(min, max) {
    return Math.floor(Math.random() * (max - min + 1)) + min;
}


var options = ['a', 'b', 'c', 'd', 'e', 'f', 'g', '1', '2', '3', '4', '5', '6'];
var operators = ['>', '<', '>=', '<=', '&&', '||', '+', '-', '=='];

function getRandomString() {
    return Math.random().toString(36).substring(7);
}

function getRandomAssert(complexity){
	var assert = "";

	if(complexity > 0){
		if(getRandomInt(0, 1) == 1){
			assert = getRandomAssert(getRandomInt(0, complexity-1))
				+ ' '
				+ operators[Math.round(Math.random()*(operators.length-1))]
				+ ' '
				+ getRandomAssert(complexity-1)
		}else{
			assert = getRandomAssert(complexity-1)
				+ ' '
				+ operators[Math.round(Math.random()*(operators.length-1))]
				+ ' '
				+ getRandomAssert(getRandomInt(0, complexity-1))
		}
	}else{
		if(getRandomInt(0, 1) == 1){
			assert = options[Math.round(Math.random()*(options.length-1))]
		}else{
			assert = options[Math.round(Math.random()*(options.length-1))]
				+ ' '
				+ operators[Math.round(Math.random()*(operators.length-1))]
				+ ' '
				+ options[Math.round(Math.random()*(options.length-1))];
		}
	}

	var ret = (getRandomInt(0, 1) == 1) ? '(' + assert + ')' : assert;

	return ret;
}

tracker.Start(function(result, error){
    if(error){
        console.log('Unable to start');
        return callback(result);
    }

    
    sendGameTraces();
    tracker.Flush(function(success, error){
    });
});