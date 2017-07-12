DAOGenerator
=====

Code generation utility for database objects(entry) and Translators based on Entity classes annotations for Realm in Swift. See more [DAO](https://github.com/RedMadRobot/DAO).

For example you have entity class

```swift
/**
 Folder Entity
 
 @model
 */
class Folder: Entity {
    
    /**
     Folder name
     
     @realm
     */
    var name: String

    /**
     Messages in folder
     
     @realm
     */
    var messages: [Message]
    
    init(entityId: String, name: String, messages: [Message]) {
        self.name = name
        self.messages = messages
    }
}

```

Then it's boring to write entry and translator by hands. Utility will generate two classes in separate files. Entry class:

```swift
class DBFolder: RLMEntry {
    dynamic var name: String = ""
    let messages = List<DBMessage>()
}

```
Translator class:

```swift
class FolderDAOTranslator: RealmTranslator<Folder, DBFolder> {

    override func fill(_ entity: Folder, fromEntry: DBFolder) {
        entity.entityId = fromEntry.entryId
        entity.name = fromEntry.name
        MessageDAOTranslator().fill(&entity.messages, fromEntries: fromEntry.messages)
    }

    override func fill(_ entry: DBFolder, fromEntity: Folder) {
        if entry.entryId != fromEntity.entityId {
            entry.entryId = fromEntity.entityId
        }
        entry.name = fromEntity.name
        MessageDAOTranslator().fill(entry.messages, fromEntities: fromEntity.messages)
    }
}
```
You can note that `Folder` class documentation includes `@model` annotation, that means generate entry and translator for that. Also there is `@realm` annotation, that means include that property into entry properties.

Table provides reference for type convertion from Entity to Entry properties:

| Type   	| Non-optional                     	| Optional                            	|
|--------	|----------------------------------	|-------------------------------------	|
| Bool   	| dynamic var value = false        	| let value = RealmOptional\<Bool>()   	|
| Int    	| dynamic var value = 0            	| let value = RealmOptional\<Int>()    	|
| Float  	| dynamic var value: Float = 0.0   	| let value = RealmOptional\<Float>()  	|
| Double 	| dynamic var value: Double = 0.0  	| let value = RealmOptional\<Double>() 	|
| String 	| dynamic var value: String = ""   	| dynamic var value: String?          	|
| Data   	| dynamic var value: Data = Data() 	| dynamic var value: Data?            	|
| Date   	| dynamic var value: Date = Date() 	| dynamic var value: Date?            	|
| Object 	| n/a: must be optional            	| dynamic var value: Class?           	|
| Array   | let value = List\<Class>()        	| n/a: must be non-optional           	|

## Setup steps

**1. Add submodule to your project.**

`git@git.redmadrobot.com:foundation-ios/DaoGenerator.git`

**2. Run `build.command` to build executable file.**

**3. Add run script phase in Xcode.**

Available arguments

| Parameter         | Description                                                                       | Example                                       |
|-------------------|-----------------------------------------------------------------------------------|-----------------------------------------------|
| help              | Print help info                                                                   | DaoGenerator -help                            |
| projectName       | Project name to be used in generated files                                        | DaoGenerator -projectName myAwesomeProject    |
| input             | Path to the folder, where header files to be processed are stored                 | DaoGenerator -input "./Model"                 |
| output_model      | Path to the folder, where generated model files should be placed                  | DaoGenerator -output_model "./Generated"      |
| output_translator | Path to the folder, where generated translator files should be placed             | DaoGenerator -output_translator "./Generated" |
| debug             | Forces generator to print names of analyzed input files and generated translators | DaoGenerator -debug                           |

**4. Add generated files manually to your project.**