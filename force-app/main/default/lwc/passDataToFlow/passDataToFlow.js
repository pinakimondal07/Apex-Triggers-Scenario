import { LightningElement,api,track,wire } from 'lwc';
import getAllRecords from '@salesforce/apex/displayAllContacts.getAllRecords'
import { FlowAttributeChangeEvent,FlowNavigationNextEvent } from 'lightning/flowSupport'

export default class PassDataToFlow extends LightningElement {
    @api contactlist; //Used to store 10 contact records.
    @api passDataToFlow; //Used to store data entered in input.
    @api availableActions = []; //Used to navigation of next screen.

    //Calling apex and it returns 10 records.
    @wire(getAllRecords)
    wiredContacts({ error, data }) {
        if (data) {
            this.contactlist = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.contactlist = undefined;
        }
    }

    //Function to handle input value change and to pass to flow.
    handleChange(event) {
        this.passDataToFlow = event.detail.value;
        const attributeChangeEvent = new FlowAttributeChangeEvent(
            'passDataToFlow',
            this.passDataToFlow
        );

        this.dispatchEvent(attributeChangeEvent);
    }
}