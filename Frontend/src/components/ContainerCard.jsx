
import { Button, Card, Flex, Text, Metric } from "@tremor/react"
import SubHeader from "./SubHeader";

function ContainerCard({ children, title, subtitle, action }) {
    return (
        <Card decoration="top" decorationColor="indigo">
            <Flex justifyContent="between">
                <div>
                    <Text>{ subtitle }</Text>
                    <Metric>{ title }</Metric>
                    <SubHeader />
                </div>
          
            { action && (
                action
            )}
            </Flex>
  
            {children}
        </Card>
    );
}

export default ContainerCard;

  