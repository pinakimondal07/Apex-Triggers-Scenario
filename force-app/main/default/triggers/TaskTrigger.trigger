trigger TaskTrigger on Task (before insert, after insert, before update) {
    List<Task> taskToUpdate = new List<Task>();
    Switch on Trigger.operationType{
        when BEFORE_INSERT{
            //1. Whenever a task is created set priority to high
            //Every trigger is a bulk Trigger
            for(Task ts : Trigger.new){
                ts.Priority = 'High';
                //In before insert there is no need to put your value into a list then insert it later to the record, 
                //we can simply assign the value
                //taskToUpdate.add(ts);
            }
            //Not required since it is a before insert
            //insert taskToUpdate;
        }
        when AFTER_INSERT{
            //19. Whenever a new Task is assigned to a Contact, increment the Number of Task Associated field value by 1
            TaskTriggerHandler.increamentTaskAssociatedOnNewTaskCreation(Trigger.new);
        }
        when BEFORE_UPDATE{
            //22. Allow updating the Task record only if the parent Contact's Account record has the Modify Task Permission checked
            TaskTriggerHandler.allowUpdateIfModifYTaskPermissionIsChecked(Trigger.new);
        }
    }
}
