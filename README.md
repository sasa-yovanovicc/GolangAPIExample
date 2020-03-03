## GO API test

## Purpose of GIT repo: Learning/example

### Task

Create a user and group management REST API service. Service should provide a way to list, add, modify and remove users and groups. Each user can belong to at most one group.

**1. Create a REST API service with the following requirements:**

- use latest Go release
- use latest go-swagger release
- use docker and Docker Compose
- write API specification in OpenAPI Specification version 2.0
- database of your choice

**2. Data model:**
**Groups:**

  - Name

**Users:**

- Email
- Password
- Name

**3. Write all needed tests.**

**4. A private git repository with full commit history is expected to be part of the delivered solution.** 

**5. Other:**

   -  if needed, provide additional installation instructions, but there shouldn't be much more than running a simple command to set everything up
   - use best practices all around


**Important: Do not take this task lightly. You will be judged according to the quality, completion and perfection of the task.**

---

## Solutions

### Current Status:  DONE

### Introduction
I found out some unlogical design patterns in go-swagger, and contacting the author of Go-Swagger was not helpful.

For example, the author (Ivan Porto Carrero) wrote me in the email  "this is not a framework it just enforces the swagger specification but you have to fill in the blanks". That is not true. You can use go-swagger and generate go files, but nothing can't avoid you to change response format - e.g in the swagger specification you declare JSON but you can force text, or HTTP code only response, and go-swagger generated files not reflect and not provide full support of swagger specification.
The second, generated code is very redundant.  E.g you can mix functions form different API calls or models without any issue.

E.g in this snippet I changed functions and mix it from different handlers and, the program works without any issue. Possibility to mix handler with functions from another handler (as result of copy-paste) can produce a lot of bugs if swagger API specification of the application is changed in the future.



```
   api.GroupsGroupGetHandler = groups.GroupGetHandlerFunc(func(params groups.GroupGetParams) middleware.Responder {
		ret, code, err := custom.GetGroup(params.GroupID)
		if err != nil {
			return groups.NewGroupListDefault(code).WithPayload(&models.Error{Code: int64(code), Message: swag.String(err.Error())})
		}
		return groups.NewGroupUpdateOK().WithPayload(ret)
	})

   api.GroupsGroupListHandler = groups.GroupListHandlerFunc(func(params groups.GroupListParams) middleware.Responder {
		ret, code, err := custom.GetGroupList(*params.Limit, *params.Offset)
		if err != nil {
			return groups.NewGroupDeleteDefault(code).WithPayload(&models.Error{Code: int64(code), Message: swag.String(err.Error())})
		}
		return groups.NewGroupGetOK().WithPayload(ret)
	})


   api.GroupsGroupDeleteHandler = groups.Group**Delete**HandlerFunc(func(params groups.GroupDeleteParams) middleware.Responder {
		code, err := custom.DeleteGroup(params.GroupID)
		if err != nil {
			return groups.NewGroup**Create**Default(code).WithPayload(&models.Error{Code: int64(code), Message: swag.String(err.Error())})
		}
		return groups.NewGroup**List**Default(code).WithPayload(&models.Error{Code: int64(code), Message: swag.String(err.Error())})
	})
```

That is not all, you are not limited in using HTTP codes, that can be different from the swagger specification in the YAML file.

Exploring examples of other developers, published on the go-swagger website, I noticed that a lot of examples don't follow the default structure of an application and they changed the way of generating program code with changing go-swagger building templates.

At first, I thought of creating my own templates for generating code, but I give up because I think that you expect a solution based on the default go-swagger file structure. This means that I can modify only one file: "configure_usersapi.go". The author suggests me on slack to change main.go and other files but those files are marked with "DO NOT EDIT".
Actually, I create additional files aside from configure_usersapi.go to make code more readable. 

The first version that I do works with common MySQL driver and just two functions, minimalistic style of coding that I like, but writing unit test for this kind of application is so hard, because in this case I sent SQL query string as parameter, and there is a lot of possibilities and lot of chances to make an error with a wrong written SQL.

The second version, that I modified a few times I create one function for each API call and use the GORM package for MySQL. I'm not a fan of ORM and I think ORMs are evil. GORM is also buggy, e.g. when you using offset you can't use Count() (that is ridiculous).

The main impact on my work has a lack of good documentation. I bought a few books about Go lang, but all the examples are too simple. Also, all examples of using go-swagger are so simple, with key-value or memory storage instead of using the database, and I spent a lot of time analyzing go-swagger generated code for better understanding how it works.


## API Structure

**Users and Groups** : Create (POST), Update (PUT), Get by ID (GET), Get all with limit and offset (GET), and Delete (DELETE) HTTP calls.

**Usergroups** : Create (POST), Get by ID (GET), Get Users in chosen Group (GET), Get Groups associated by User (GET), and Delete (DELETE) HTTP calls.
Update (PUT) is not created for Usergroups, because Usergroups table is in relation to Users and Groups and contains only Ids of Users and Groups. In real-life in this kind of tables data are not editable, but wrong can be deleted. 

Also, the database has foreign keys, to preserve the data structure. If you delete certain users from the database,  their records in the Usergroups table will be deleted. But, you can't delete groups in the same way as users, if a group is not empty (without users).
This kind of conflict is supported in API and produces an error message with HTTP code 409.

The default HTTP code for delete is not 204 because I like to return JSON. HTTP code 204 doesn't allow the body in response. Because of this, I used HTTP code 200 for deleting too, like for other successful operations, except creating where I used HTTP code 201.

Create, Update and Delete functions return three response variables: return (models.* ), error code as an int, and error message as a string. Without sending error code, I would have to write HTTP code twice - once in custom function and second in the handler function. Other (Get) function return two parameters: error code and message.

Some functions are complex like this one because on deleting group requests, I check is the group has members. If the group has members, this group can't be deleted.

```
func DeleteGroup(GroupID int64) (code int, error error) {
	var usergroup []models.Usergroups
	db := dbConn()
	group := GroupStruct{}

// first find group by id because delete can't return error
	db.Where("group_id = ?", GroupID).Find(&usergroup)

	if len(usergroup) > 0 {
		return 409, errors.New(409, messages["groupIsNotEmpty"])
	}

	err := db.Where("id = ?", GroupID).Find(&group).RecordNotFound()

	if err == true {
		return 404, errors.New(404, messages["groupNotFound"])
	}
	db.Where("id = ?", GroupID).Delete(&group)

	return 200, errors.New(200, messages["deleted"])
}
```

Or, e.g., on creation User-Group pair in usergroups table, need to be checked: JSON validation, there must be present UserID and GroupID, check if that pair already exists and, check if user or group exists, to prevent storing non-existing user id or group id. Of course, foreign keys prevent storing this kind of data but I like to check this in the application and return a human-readable error message. 

```
func CreateUserGroup(params *models.Usergroups) (code int, error error) {
	db := dbConn()
	defer db.Close()
	if params.UserID == 0 || params.GroupID == 0 {
		//  422 Unprocessable Entity
		message := messages["incompleteJSON"]
		return 422, errors.New(422, message)
	}
	// omit ID
	usergroup := UserGroupStruct{UserID: params.UserID, GroupID: params.GroupID}
	user := UserStruct{}
	group := GroupStruct{}
	//check: is user-group pair already exists?
	err1 := db.Where("user_id = ? AND group_id=?", params.UserID, params.GroupID).First(&usergroup).RecordNotFound()

	if err1 == false {
		// Conflict, HTTP Code 409
		message := messages["usergroupExists"]
		return 409, errors.New(409, message)
	}
	err2 := db.Where("id = ?", params.UserID).First(&user).RecordNotFound()
	if err2 == true {
		err3 := db.Where("id = ?", params.GroupID).First(&group).RecordNotFound()
		if err3 == true {
			message := messages["userIdNotExist"] + " and " + messages["groupIdNotExist"]
			return 404, errors.New(404, message)
		}
		message := messages["userIdNotExist"]
		return 404, errors.New(404, message)
	}
	err4 := db.Where("id = ?", params.GroupID).First(&group).RecordNotFound()
	if err4 == true {
		message := messages["groupIdNotExist"]
		return 404, errors.New(404, message)
	}

	db.NewRecord(usergroup)
	db.Create(&usergroup)
	db.NewRecord(usergroup)

	params.ID = usergroup.ID
	return 201, nil
}

```

## Unit tests
The test covers all custom writing functions. Autogenerated functions haven't tested, and also basic functions in configure_usersapi.go not covered with tests because they just call custom functions in /restapi/custom/usersapi_func.go 

Two functions envLoad() - loading environment variables and, dbConn() - connecting database, and three "TableName" functions that just return table name not covered with unit test, because haven't sense test functions without they application can't start. 

## Instalation

After cloning repository type

```
./scripts/install.sh
```

and choose option from menu:
```

 Select the option
 =========================================
  PREPARE LOCAL env (do 1,2,3 first)
 =========================================
   1) Install build tools
   2) Create MySQL database
   3) Generate code with Swagger
 =========================================
  LOCAL test, doc and run
 =========================================
   4) Display OpenAPI Doc
   5) Validate Swagger API sepecification
   6) Run API
   7) Run Unit tests
 =========================================
  DOCKER env
 =========================================
   8) Create and run Docker image
      (mysql: golang_db, go: golang_app)
 =========================================
  Q) Quit
```
Before local use and tests, you should do 1, 2 and 3 to prepare application and database.

Options 4-5 show documentation (4), validate swagger file (5), Run API in the local environment (6) and, Run Unit tests (7) 

Option 8 generates an application for docker and creates two docker images: one for MySQL (golang_db) and the second one for the Go app (golang_app). Apps start immediately after docker creating.

Manually you can start docker by **docker start <name of container>**: ***docker start golang_db; docker start goland_app***.

### Installation scripts

Located in the folder /scripts
>
> build_docker.sh                ***BUILD DOCKER containers***
>
> build_tools_install.sh         ***Install building tools: swagger, open-api and others***
>
> build_vendor.sh                ***Install vendor packages in the folder vendor, after completing app***
>
> copy_post_code_gen_docker.sh   ***Copy custom files and tests to /restapi and /restapi/custom folders (docker version)***
>
> copy_post_code_gen.sh          ***Copy custom files, only for local environment, difference in database call***
>
> install.sh                     ***Installation menu***
>
> mysql_db_create.sh             ***Create local database from /spec/test.sql (you should know root username and password)***
>
> run_unit_tests.sh              ***Start unit tests (local env and docker if start it inside docker container)***
>
> swagger_code_gen.sh            ***Generate files from swagger yaml specfiication***
>
>

### Workflow of docker creation (option 8 in install menu)

1) Check if mysql servcie running and stooped it

2) Install building tools

3) The go-swagger generate code (bash script ./scripts/swagger_code_gen.sh) based on specification in the folder /spec/

4) Copy custom files 

5) Install vendor packages

6) Create docker containers based on docker-compose.yml file


### Docker configuration

Docker configuration is specified in the docker-compose.yml file in the root of the application, and in two Dockerfile files in the folders:

/docker/go

and

/docker/mysql

Due to context limitations, test.sql are stored again in the /docker/mysql folder, together with the Dockerfile.

### Environment variables (database)
Environment variables are stored in .env file in the root.

But, the test fails because they cannot find the file .env. Because of this scripts copied .env files to restapi and retapi/custom folders.

Source: [https://github.com/joho/godotenv/issues/43](https://github.com/joho/godotenv/issues/43) (Can't use godotenv when running tests)


