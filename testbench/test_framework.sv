
// Interface
/*
 * This compoenet is a container encapsulates input-output ports into
 * a container (an interfacce). This design can then be driven with 
 * values through this interface.
 *
 */

// Driver:
// A verification compoent that converts data transactions 
// into signals that the DUT can understand.
/*
 * Does pin-wiggling of DUT through a task defined in the interface.
 * When it drives some input values to design, it calls some pre-defined task in
 * the interface. This is helpful as it provides a level of abstarction making 
 * testbenches more flexiable and scalab.e
 * If the interface changes, then the new driver can call the same task and drive 
 * signals in a different way.
 */

// Gets a transaction from amilbox
class driver;
    virtual reg_if vif;
    event rv_done;


// Generator:
/*
 * Verification compoenet that can cerate valid data transaction and send
 * them to the driver. The driver can then simply drive the data provided to it
 * by the generator throug hthe dinterface.
 * ( Data transactions are implemented as class objects shown by blue squares).
 */


// Monitor
/*
 * After the driver transforms transactions into the corresponding 
 * input signals, the DUT will process it and send the results to the 
 * output pins. The monitor pciks up this processed data, converts it into a data object,
 * and send it to the scoreboard.
 */

// Interface
/*
 * Allows verifcation compoenents to access DUT signals using this interface handle.
 */

// Scoreboard
/*
 * Reference mode that behaves the same way as the DUT (or rather the functional description version)
 * It severs as the reference model and determines defects in the functionality of the DUT.
 */

// Environment
/*
 * The verifcation becomes more fleixable and scalable as more componenets can be plugged
 * into the same environment for future projects.
 */

class env;
    driver          d0;     // Driver to design
    monitor         m0;     // Monitor from design
    scoreboard      s0;
    mailbox         scb_mbx;    // Top level mailbox (used to pass transaction objects between SCB <-> MON)
    virtual reg_if  vif;

