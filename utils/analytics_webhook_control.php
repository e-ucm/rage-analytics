<?php

/**
 * Copyright 2019 e-UCM (http://www.e-ucm.es/), Ivan J. Perez Colado
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * This project has received funding from the European Union’s Horizon
 * 2020 research and innovation programme under grant agreement No 644187.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0 (link is external)
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * 
 * This script contains documentation for the required API calls needed to manage the analytics
 * server in a simplified way by the FormalZ framework by using the Analytics Webhook instead
 * of directly calling methods from Analytics A2 and Analytics Backend.
 *
 * For authentication there will be used the enpoint https://analytics.e-ucm.es/api/login/formalz
 * To log in an user only the ID is needed, however, request must be authenticated by a user
 * with the role 'formalzadmin'. User given 'formalz-admin-test' is available for testing, but
 * contact us if you want to add the 'formalzadmin' role to other user.
 *
 * To authenticate the request we will use the header:
 * 'Authorization' => 'Bearer ' . AdminAnalyticsController::GetInstance()->GetAdminToken()
 * Take a look to the code if you want to know more details.
 *
 * The BaseURL used for this example is: https://analytics.e-ucm.es/api/proxy/webhook/
 * 
 * There are a total of 6 requests:
 * - POST /events/collector/user_created
 * - POST /events/collector/room_created
 * - POST /events/collector/room_participants_added
 * - POST /events/collector/room_participants_removed
 * - POST /events/collector/room_removed
 * - POST /events/collector/puzzle_created
 *
 * More documentation:
 * - http://e-ucm.github.io/a2/
 * - http://e-ucm.github.io/rage-analytics-backend/
 * - https://github.com/e-ucm/beaconing-analytics-webhook/tree/formalz
 */

const BASE_URL = 'https://analytics.e-ucm.es/';
const WEBHOOK_URL = BASE_URL . 'api/proxy/webhook/';
const KIBANA_URL = BASE_URL . 'api/proxy/kibana/';
const ADMIN_USERNAME = 'formalz-admin-test';
const ADMIN_PASSWORD = 'admintest123456';

// ##################################################
// ################## MAIN PROGRAM ################## 
// ##################################################


try {
    echo '<h1>Analytics tester PHP</h1>';
    // 0 - Optional - Create a teacher user using the AdminAnalyticsController
    // If you have already created one with that id, you will get an error.
    $user = AdminAnalyticsController::GetInstance()->createUser('ucm2', 'teacher_ucm_test_2', 'teacher');
    
    // 1 - Init the Analytics controller for the created user
    $teachercontroller = new AnalyticsController('ucm2');
    
    // 2 - Create students.
    $student = $teachercontroller->createStudent('ucm2_student1', 'student_ucm_test_2');

    echo '<h2>Creating the student</h2>';
    var_dump($student);
    echo '<br><br>';
    
    // 3 - Create a room. Students array is optional as students can be added later.
    $result = $teachercontroller->createRoom('ucm2_room1', 'A test room for PHP', array('ucm2_student1'));

    echo '<h2>Creating the room</h2>';
    var_dump($result);
    echo '<br><br>';
    
    // 4 - Optional - Add students/teachers to the room.
    $result = $teachercontroller->addParticipants('ucm2_room1',
        array(
            'students' => array('ucm2_student1'/*, 'other_student'*/),
            //'teachers' => array('whatever_teacher_id','')
        )
    );

    echo '<h2>Adding the participants</h2>';
    var_dump($result);
    echo '<br><br>';

    // 5 - Optional - remove students/teachers to the room.
    /*$result = $teachercontroller->removeParticipants('ucm2_room1',
        array(
            'students' => array('ucm2_student1', 'other_student'),
            //'teachers' => array('whatever_teacher_id','')
        )
    );*/


    // 6 - Optional - remove the room.
    //$result = $teachercontroller->removeRoom('ucm2_room1');

    $puzzle = $teachercontroller->createPuzzle('ucm2_room1');

    echo '<h2>Creating the puzzle</h2>';
    var_dump($puzzle);
    echo '<br><br>';

    $dashboard_url = KIBANA_URL . 'app/kibana#/dashboard/dashboard_' . $puzzle['activity'] . '?embed=true';

    echo '<strong>Dashboard Link: </strong><a href="' . $dashboard_url . '" target="_blank">' . $dashboard_url . '</a>';
} catch (Exception $e) {
    echo $e->getMessage();
}


// ######################################################################
// ################## FUNCTIONS RELATED WITH API CALLS ################## 
// ######################################################################

class AdminAnalyticsController {
    private static $instance;
    private $admin_token = null;
    private $lastauth = null;

    static public function GetInstance(){
        if(!isset(self::$instance)){
            self::$instance = new AdminAnalyticsController();
        }
        return self::$instance;
    }

    private function __construct(){
    }

    public function GetAdminToken(){
        if(!isset($this->admin_token) || (time() - $this->lastauth > 1800)){
            $this->AdminLogin();
        }

        return $this->admin_token;
    }

    private function AdminLogin(){
        $result = request(
                BASE_URL . 'api/login',
                array('Content-Type' => 'application/json', 'Accept' => 'application/json'),
                array('username' => ADMIN_USERNAME, 'password' => ADMIN_PASSWORD)
            );

        if(isset($result['error'])){
            throw new Exception("Error on admin login: " . json_encode($result['error']), 1);
        }

        $this->admin_token = $result['result']['user']['token'];

        return $result['result']['user']['token'];
    }

    /**
     * Creates a user for the logged with the external id from formalz. 
     * IMPORTANT: Teachers can only create students. If you want to create a teacher use admin account.
     *     
     * @param  string $id       ExternalID for the user to be created (IDs are UNIQUE).
     * @param  string $username Username of the user to be created (Usernames are UNIQUE).
     * @param  string $role     Role of the user to be created. Role can be student or teacher.
     * @return object           Object of the user created.
     */
    function createUser($id, $username, $role){
        $result = request(
                WEBHOOK_URL . 'events/collector/user_created',
                array(
                    'Content-Type' => 'application/json',
                    'Accept' => 'application/json',
                    'Authorization' => 'Bearer ' . $this->GetAdminToken()
                ),
                array('id' => $id, 'username' => $username, 'role' => $role)
            );

        if(isset($result['error'])){
            throw new Exception("Error creating user: " . json_encode($result['error']), 1);
        }

        return $result['result'];
    }
}

class AnalyticsController {
    private $userid = null;
    private $auth_token = null;
    private $lastauth = null;

    public function __construct($userid){
        $this->userid = $userid;
    }

    /**
     * Returns the AuthToken for this logged teacher
     */
    function GetAuthToken(){
        if(!isset($this->auth_token) || (time() - $this->lastauth > 1800)){
            $this->Login();
        }

        return $this->auth_token;
    }

    /**
     * Performs the login and saves the auth token into the internal auth_token variable.
     */
    function Login(){
        $result = request(
                BASE_URL . 'api/login/formalz',
                array(
                    'Content-Type' => 'application/json',
                    'Accept' => 'application/json',
                    'Authorization' => 'Bearer ' . AdminAnalyticsController::GetInstance()->GetAdminToken()
                ),
                array('id' => $this->userid)
            );

        if(isset($result['error'])){
            throw new Exception("Error on user login: " . json_encode($result['error']), 1);
        }

        $this->auth_token = $result['result']['user']['token'];

        return $this->auth_token;
    }

    /**
     * Creates a student for the logged teacher. 
     * IMPORTANT: Teachers can only create students. If you want to create a teacher use admin account.
     *     
     * @param  string $id       ExternalID for the user to be created (IDs are UNIQUE).
     * @param  string $username Username of the user to be created (Usernames are UNIQUE).
     * @return object           Object of the user created.
     */
    function createStudent($id, $username){
        $result = request(
                WEBHOOK_URL . 'events/collector/user_created',
                array(
                    'Content-Type' => 'application/json',
                    'Accept' => 'application/json',
                    'Authorization' => 'Bearer ' . $this->GetAuthToken()
                ),
                array('id' => $id, 'username' => $username, 'role' => 'student')
            );

        if(isset($result['error'])){
            throw new Exception("Error creating the student: " . json_encode($result['error']), 1);
        }

        return $result['result'];
    }

    /**
     * Creates a room with the external ID, name, and optional students including the logged teacher
     * as participant
     * 
     * @param  string $id       ExternalID of the room to be created
     * @param  string $name     Descriptive name of the room
     * @param  array  $students List of students to be added to the room
     * @return array            Request response, usually success message.
     */
    function createRoom($id, $name, $students = null){

        $body = array('id' => $id, 'name' => $name);
        if(isset($students) && is_array($students)){
            $body['students'] = $students;
        }

        $result = request(
                WEBHOOK_URL . 'events/collector/room_created',
                array(
                    'Content-Type' => 'application/json',
                    'Accept' => 'application/json',
                    'Authorization' => 'Bearer ' . $this->GetAuthToken()
                ),
                $body
            );

        if(isset($result['error'])){
            throw new Exception("Error creating the room: " . json_encode($result['error']), 1);
        }

        return $result['result'];
    }

    /**
     * Removes a room using the given external ID.
     * 
     * @param  string $id External ID of the room to remove.
     * @return array      Request response, usually success message.
     */
    function removeRoom($id){

        $result = request(
                WEBHOOK_URL . 'events/collector/room_removed',
                array(
                    'Content-Type' => 'application/json',
                    'Accept' => 'application/json',
                    'Authorization' => 'Bearer ' . $this->GetAuthToken()
                ),
                array('id' => $id)
            );

        if(isset($result['error'])){
            throw new Exception("Error creating the room: " . json_encode($result['error']), 1);
        }

        return $result['result'];
    }

    /**
     * Adds participants (either teachers or students) to a given room
     * @param string $roomId       External ID of the room where the participants are going to be added
     * @param array  $participants It can contain two arrays: {students: [], teachers: []} both optional.
     * @return array               Request response, usually success message.
     */
    function addParticipants($roomId, $participants){

        $result = request(
                WEBHOOK_URL . 'events/collector/room_participants_added',
                array(
                    'Content-Type' => 'application/json',
                    'Accept' => 'application/json',
                    'Authorization' => 'Bearer ' . $this->GetAuthToken()
                ),
                array('id' => $roomId, 'participants' => $participants)
            );

        if(isset($result['error'])){
            throw new Exception("Error adding participants to the room: " . json_encode($result['error']), 1);
        }

        return $result['result'];
    }

    /**
     * Removes participants (either teachers or students) from a given room
     * @param string $roomId       External ID of the room where the participants are going to be added
     * @param array  $participants It can contain two arrays: {students: [], teachers: []} both optional.
     * @return array               Request response, usually success message.
     */
    function removeParticipants($roomId, $participants){

        $result = request(
                WEBHOOK_URL . 'events/collector/room_participants_removed',
                array(
                    'Content-Type' => 'application/json',
                    'Accept' => 'application/json',
                    'Authorization' => 'Bearer ' . $this->GetAuthToken()
                ),
                array('id' => $roomId, 'participants' => $participants)
            );

        if(isset($result['error'])){
            throw new Exception("Error removing participants from the room: " . json_encode($result['error']), 1);
        }

        return $result['result'];
    }

    /**
     * Creates a puzzle activity into the analytics server and prepares it for traces to be sent.
     * @param  string $roomId The external ID of the room where the puzzle is created
     * @return array          Includes 'activity' being the ID for dashboards and 'trackingCode' for the
     *                        tracker to send traces to. It is recommended to persist both of them.
     */
    function createPuzzle($roomId){

        $result = request(
                WEBHOOK_URL . 'events/collector/puzzle_created',
                array(
                    'Content-Type' => 'application/json',
                    'Accept' => 'application/json',
                    'Authorization' => 'Bearer ' . $this->GetAuthToken()
                ),
                array('room' => $roomId)
            );

        if(isset($result['error'])){
            throw new Exception("Error removing participants from the room: " . json_encode($result['error']), 1);
        }

        return $result['result'];
    }
}

// #####################################################################
// ################## UTIL FUNCTIONS FOR THE REQUESTS ################## 
// #####################################################################

function request($url, $headers, $body){
    $resultobject = array();

    $options = array(
        'http' => array(
            'header' => formatheaders($headers),
            'method' => 'POST',
            'content' => json_encode($body),
            'ignore_errors' => true
        )
    );
    $context = stream_context_create($options);
    $result = file_get_contents($url, false, $context);
    $code = getHttpCode($http_response_header);

    $resultobject['code'] = $code;
    $resultobject['context'] = $options;
    $resultobject['context']['url'] = $url;
    
    if ($result === FALSE) {
        $resultobject['error'] = true;
    }else{
        $decoded = json_decode($result, true);

        if($decoded){
            if($code !== 200){
                $resultobject['error'] = $decoded;
            }else{
                $resultobject['result'] = $decoded;
            }
        }else{
            $resultobject['error'] = true;
        }
    }

    return $resultobject;
}

function formatheaders($headers){
    $formatted = "";

    foreach ($headers as $key => $content) {
        $formatted .= $key . ': ' . $content . "\r\n";
    }

    return $formatted;
}

function getHttpCode($http_response_header)
{
    if(is_array($http_response_header))
    {
        $parts=explode(' ',$http_response_header[0]);
        if(count($parts)>1) //HTTP/1.0 <code> <text>
            return intval($parts[1]); //Get code
    }
    return 0;
}