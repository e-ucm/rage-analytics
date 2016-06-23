/*
  Jasmine docs: 
    http://jasmine.github.io/2.0/introduction.html
  
  Basic tests:
    expect(aValue).toBe(value)
        .toMatch(regex)
        .not.toBeUndefined()
        .toBeTruthy();
        .toContain("bar");
        .toBeLessThan(pi);
    expect(aFunction).toThrow();
    expect(12).toEqual(jasmine.any(Number));  
        
  Protractor ref: 
    http://www.protractortest.org/#/api
  
  Protractor vs WebDriverJS: 
    http://www.protractortest.org/#/webdriver-vs-protractor
  webdriver.By -> by
  browser.findElement(...) -> element(...)
  browser.findElements(...) -> element.all(...)
  browser.findElement(webdriver.By.css(...)) -> $(...)
  browser.findElements(webdriver.By.css(...)) -> $$(...)
*/

var afront = {
    url: 'http://localhost:3000/api/proxy/afront/',
    
    addUser: function(login, role, pass, email) {
        pass = typeof pass !== 'undefined' ? pass : login;
        email = typeof email !== 'undefined' ? email : email + '@example.com';
        switch(role) {
            case 'dev': role = '.fa-code'; break;
            case 'tea': role = '.fa-book'; break;
            case 'stu': role = '.fa-graduation'; break;
        }

        browser.get(this.url + 'signup')
        element(by.model('user.username')).sendKeys(login);
        element(by.model('user.password')).sendKeys(pass);
        element(by.model('user.email')).sendKeys(email);
        element(by.model('repeatedPassword')).sendKeys(pass);
        element(by.css(role)).click()
        
        element(by.css('.btn-signup')).click();
    },
    
    login: function(login, pass) {
        pass = typeof pass !== 'undefined' ? pass : login;

        browser.get(this.url + 'login');
        element(by.model('user.username')).sendKeys(login);
        element(by.model('user.password')).sendKeys(pass);
        
        element(by.css('.btn-login')).click();
    },
    
    logout: function() {
        browser.get(this.url + 'home');
        element(by.id('dropdownUser')).click();
        element(by.css('.fa-sign-out')).click();
    },
    
    addGame: function(title) {
        browser.get(this.url + 'home');
        element(by.model('game.gameTitle')).sendKeys(title);        
        element(by.css('.btn-primary')).click();
    },

    removeFirstGame: function() {
        browser.get(this.url + 'home');
        element(by.css('.glyphicon-remove-sign')).click();
    },
    
    gameFromDropdown: function(title) {
        browser.get(this.url + 'home');
        element(by.id('dropdownGames')).click();
        element(by.id('dropdownGames').by.linkText(title)).click()
    },
    
    countGamesInDropdown: function() {
        return element.all(by.id('dropdownGames')).count()
    },

    countGamesInHome: function() {
        return element.all(by.css('.glyphicon-stats')).count()
    },
    
    gotoGameAnalysis: function() {
        element(by.cssContainingText('.left-menu-item', 'Analysis')).click()
        expect(element(by.cssContainingText('.left-menu-item', 'Analysis')).getAttribute('class'))
            .toContain('active');
    },
    
    
}

describe('When creating users', function() {
   
    it('should create a dev user (dev)', function() {
        afront.addUser('dev', 'dev');
    });

    it('should create a teacher user (tea)', function() {
        afront.addUser('tea', 'tea');
    });
        
    it('should fail login with bad pass', function() {
        afront.login('dev', 'badpass');
        expect(browser.getCurrentUrl()).toContain('/login');
    });
    
    it('should login with good pass as dev', function() {
        afront.login('dev', 'dev');
        expect(browser.getCurrentUrl()).toContain('/home');
    });
        
    it('should logout correctly', function() {
        afront.logout();
        expect(browser.getCurrentUrl()).toContain('/login');
    });    
    
    it('should login with good pass as tea', function() {
        afront.login('tea', 'tea');
        expect(browser.getCurrentUrl()).toContain('/home');
        afront.logout();
        expect(browser.getCurrentUrl()).toContain('/login');
    });
});

describe('When logged as dev', function() {
    
    var gameUrl;
    
    it('should create games (testgame)', function() {
        afront.login('dev', 'dev');
        expect(browser.getCurrentUrl()).toContain('/home');
        
        expect(afront.countGamesInDropdown()).toBe(0);
        
        afront.addGame('testgame');
        gameUrl = browser.getCurrentUrl();
        expect(gameUrl).toMatch(/.*?game=[a-z0-9]+&version=[a-z0-9]+/);
        expect(afront.countGamesInDropdown()).toBe(1);        
    });
    
    it('should remove games', function() {
        expect(afront.countGamesInDropdown()).toBe(1);        
        afront.removeFirstGame();
        expect(afront.countGamesInHome()).toBe(0);
    });
    
    it('should keep dropdown and home games table in sync', function() {
        expect(afront.countGamesInDropdown()).toBe(afront.countGamesInHome());
    });
});

describe('When releasing kibana', function() {
    
    it('should create games (testgame)', function() {
        afront.login('dev', 'dev');
        expect(browser.getCurrentUrl()).toContain('/home');
        afront.addGame('testgame');
        gameUrl = browser.getCurrentUrl();
        expect(gameUrl).toMatch(/.*?game=[a-z0-9]+&version=[a-z0-9]+/);
    });
});
        