let money = prompt('Ваш бюджет на месяц?');
let time = prompt('Введите дату в формате YYYY-MM-DD');


var appData = {};
appData.budget = money; 
appData.timeData = time; 
appData.expenses = {};
appData.optionalExpenses = {};
appData.income = [];
appData.savings = false;

let q1 = prompt('1. Введите обязательную статью расходов в этом месяце', '');
appData.expenses[q1] = prompt('1. Во сколько обойдется?', '');

let q2 = prompt('2. Введите обязательную статью расходов в этом месяце', '');
appData.expenses[q2] = prompt('2. Во сколько обойдется?', '');

alert('1. Ваш бюджет на 1 день : ' + appData.expenses[q1]/30 + ' для ' + q1 +
' \n2. Ваш бюджет на 1 день: ' + appData.expenses[q2]/30 + ' для ' + q2);