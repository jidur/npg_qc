//Adjusting root for tests.
var TestConfiguration = (function() {
  function TestConfiguration () {
  }
    
  TestConfiguration.prototype.getRoot = function() {
    return 'test/images';
  };
    
  return TestConfiguration;
}) ();

test('Object initialisation', function() {
  var obj = null;
  ok(obj == null, "Variable is initially null.");
  obj = new NPG.QC.LaneMQCControl();
  ok(obj !== undefined, "Variable is now an instance.");
  ok(obj.index === undefined, "Object has no initial index.");
  obj = new NPG.QC.LaneMQCControl(0, new TestConfiguration());
  ok(obj !== undefined, "Variable is now a new instance called with parameters for constructor.");
  ok(obj.index !== undefined, "New object has an initial index.");
  ok(obj.lane_control == null, "New object has null lane_control.");
  ok(obj.outcome == null, "New object has null outcome.");
    
  obj = new NPG.QC.RunMQCControl();
  ok(obj !== undefined, 'variable is now an instance of RunMQCControl'); 
  obj = new NPG.QC.RunMQCControl(1, new TestConfiguration());
  ok(obj !== undefined, 'variable is now an instance of RunMQCControl');
  
  obj = new NPG.QC.RunTitleParser();
  ok(obj !== undefined, 'variable is now an instance of RunTitleParser');
});
