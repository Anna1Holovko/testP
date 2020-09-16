@isTest
private Class SystemUtilsTest {

      static testMethod void validateLengthShouldReturnUniqueCodeWithThirtyTwoCharacters() {
           String uniqueCode = SystemUtils.generateUUID();
           System.assertequals(uniqueCode.length(),32 );
      }

      static testMethod void validateSpecialCharactersShouldReturnUniqueCodeWithoutSpecialCharacters() {
           String specialCharacters = '!@#$%^&*()-+*/';
           String uniqueCode = SystemUtils.generateUUID();
           Boolean success = true;
           for(integer i=0; i<specialCharacters.length(); i++) {
                if(uniqueCode.contains('+specialCharacters[i]+')){ 
                    success = false;   
                    break;  
                }    
           }
           System.assertequals(success,true);
      }
}